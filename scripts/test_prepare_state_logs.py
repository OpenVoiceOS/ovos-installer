"""Regression coverage for reclaiming full Mycroft state tmpfs on upgrades."""
import importlib.util
from pathlib import Path
import tempfile
import subprocess
import json
import base64
import copy
import jinja2
import yaml
from ansible.plugins.filter.core import combine, to_json, to_bool
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / 'ansible/roles/ovos_storage_tuning/files/prepare_state_logs.py'
spec = importlib.util.spec_from_file_location('prepare_state_logs', SCRIPT)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


class StateLogsTest(unittest.TestCase):
    def test_preserves_logs_reclaims_space_and_keeps_schedule(self):
        """Preserves logs reclaims space and keeps schedule."""
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'state'
            state.mkdir()
            archive = Path(directory) / 'archive'
            log = state / 'skills.log'
            log.write_bytes(b'x' * 101)
            inode = log.stat().st_ino
            (state / 'gui.log.1').write_bytes(b'old log')
            (state / 'voice.log').write_bytes(b'small')
            (state / 'schedule.json').write_text('{"event": 1}')
            (state / 'link.log').symlink_to(log)
            module.prepare_logs(state, archive, limit=100)
            self.assertEqual(log.stat().st_ino, inode)
            self.assertEqual(log.stat().st_size, 0)
            self.assertFalse((state / 'gui.log.1').exists())
            self.assertEqual((state / 'voice.log').read_bytes(), b'small')
            self.assertEqual((state / 'schedule.json').read_text(), '{"event": 1}')
            self.assertTrue((state / 'link.log').is_symlink())
            self.assertEqual(sorted(p.read_bytes() for p in archive.iterdir()), [b'old log', b'x' * 101])
            module.prepare_logs(state, archive, limit=100)
            self.assertEqual(len(list(archive.iterdir())), 2)
            # Scheduler writes are possible after recovery.
            (state / 'schedule.json.tmp').write_text('{"event": 2}')
            (state / 'schedule.json.tmp').replace(state / 'schedule.json')

    def test_copy_failure_leaves_original_intact(self):
        """Copy failure leaves original intact."""
        with tempfile.TemporaryDirectory() as directory:
            state = Path(directory) / 'state'
            state.mkdir()
            log = state / 'skills.log'
            log.write_bytes(b'diagnostics')
            with patch.object(module.shutil, 'copyfileobj', side_effect=OSError('disk full')):
                with self.assertRaises(OSError):
                    module.prepare_logs(state, Path(directory) / 'archive', limit=1)
            self.assertEqual(log.read_bytes(), b'diagnostics')

    def test_boot_archives_small_and_newly_rotated_persisted_logs(self):
        """A restore followed by destructive sync must retain prior diagnostics."""
        with tempfile.TemporaryDirectory() as directory:
            persist, live, archive = (Path(directory) / n for n in ('persist', 'live', 'archive'))
            persist.mkdir()
            live.mkdir()
            (persist / 'skills.log').write_bytes(b'small prior boot log')
            (persist / 'gui.log.1').write_bytes(b'rotated after installer ran')
            (persist / 'schedule.json').write_text('{"event": 1}')
            module.prepare_logs(persist, archive, archive_all=True)
            subprocess.run(['rsync', '-a', '--exclude=*.log', '--exclude=*.log.*', str(persist) + '/', str(live) + '/'], check=True)
            (live / 'skills.log').write_bytes(b'new boot log')
            (live / 'schedule.json').write_text('{"event": 200}')
            subprocess.run(['rsync', '-a', '--delete', str(live) + '/', str(persist) + '/'], check=True)
            self.assertEqual(sorted(p.read_bytes() for p in archive.iterdir()),
                             sorted([b'small prior boot log', b'rotated after installer ran']))
            self.assertEqual((persist / 'schedule.json').read_text(), '{"event": 200}')
            module.prepare_logs(persist, archive, archive_all=True)
            self.assertIn(b'new boot log', [p.read_bytes() for p in archive.iterdir()])


class LoggingConfigurationTest(unittest.TestCase):
    def render(self, method='virtualenv', logs=None, logging=None, active=True, mounts=None, **extra):
        """Render the actual logging template and tmpfs predicate with Ansible filters."""
        path = SCRIPT.parents[2] / 'ovos_config/templates/mycroft.conf.j2'
        source = path.read_text().split('{% set _ovos_is_raspberry_pi_4')[0]
        source = '\n'.join(source.splitlines()[1:]) + '"test": true}'
        env = jinja2.Environment()
        env.filters['combine'] = combine
        env.filters['to_json'] = to_json
        env.filters['bool'] = to_bool
        variables = dict(
            ovos_installer_method=method, ovos_config_logs_max_bytes=1000000,
            ovos_config_logs_backup_count=1, ovos_config_existing_logs=logs or {},
            ovos_config_existing_logging=logging or {},
            ovos_storage_tuning_mycroft_state_active=active,
            ovos_installer_user_home='/home/test',
            ansible_facts={'mounts': mounts or []})
        variables.update(extra)
        defaults = yaml.safe_load((path.parents[1] / 'defaults/main.yml').read_text())
        expression = defaults['ovos_config_state_tmpfs_enabled'].strip()[2:-2].strip()
        variables['ovos_config_state_tmpfs_enabled'] = env.compile_expression(expression)(**variables)
        return json.loads(env.from_string(source).render(**variables))

    def test_disk_backed_hosts_keep_their_defaults_and_overrides(self):
        """Disk backed hosts keep their defaults and overrides."""
        for hardware in ('N/A', 'Raspberry Pi 4 Model B', 'Raspberry Pi 5'):
            with self.subTest(hardware=hardware):
                config = self.render(active=False, ovos_installer_raspberrypi=hardware)
                self.assertNotIn('logs', config)
                self.assertNotIn('logging', config)
        existing = {'path': '/disk/logs', 'max_bytes': 50000000, 'backup_count': 3}
        logging = {'gui': {'logs': {'path': '/disk/gui'}, 'log_level': 'DEBUG'}}
        config = self.render(active=False, logs=existing, logging=logging)
        self.assertEqual(config['logs'], existing)
        self.assertEqual(config['logging'], logging)

    def test_existing_mounts_and_custom_state_paths(self):
        """Existing mounts and custom state paths."""
        path = '/home/test/.local/state/mycroft'
        config = self.render(active=False, mounts=[{'mount': path, 'fstype': 'tmpfs'}])
        self.assertEqual(config['logs']['max_bytes'], 1000000)
        for mount in ({'mount': path, 'fstype': 'ext4'}, {'mount': '/tmp', 'fstype': 'tmpfs'}):
            self.assertNotIn('logs', self.render(active=False, mounts=[mount]))
        config = self.render(active=False, mounts=[{'mount': '/custom/state', 'fstype': 'tmpfs'}],
                             ovos_installer_tuning_mycroft_state_dir='/custom/state')
        self.assertEqual(config['logs']['backup_count'], 1)

    def test_native_defaults_and_explicit_overrides(self):
        """Native defaults and explicit overrides."""
        self.assertEqual(self.render()['logs'], {'max_bytes': 1000000, 'backup_count': 1})
        logs = self.render(logs={'path': '/disk/logs', 'max_bytes': 2000000})['logs']
        self.assertEqual(logs, {'path': '/disk/logs', 'max_bytes': 2000000, 'backup_count': 1})
        config = self.render(logging={'logs': {'path': '/custom'}, 'gui': {'log_level': 'WARNING'}})
        self.assertEqual(config['logging']['logs']['max_bytes'], 1000000)
        self.assertEqual(config['logging']['logs']['path'], '/custom')
        self.assertEqual(config['logging']['gui']['log_level'], 'WARNING')

    def test_real_ansible_preservation_tasks(self):
        """Real ansible preservation tasks."""
        root = SCRIPT.parents[4]
        tasks = yaml.safe_load((root / 'ansible/roles/ovos_config/tasks/install.yml').read_text())
        preserve = next(t for t in tasks if t['name'] == 'Preserve existing file logging configuration')
        existing = {'logs': {'max_bytes': 5000000, 'path': '/logs/http://host/#keep'},
                    'logging': {'gui': {'log_level': 'DEBUG', 'logs': {'path': '/disk/gui'}}}}
        plays = []
        for enabled, commented in ((True, False), (False, False), (True, True), (False, True)):
            expected = copy.deepcopy(existing['logging'])
            if enabled:
                expected['gui']['logs'].update(max_bytes=1000000, backup_count=1)
            plays.append(dict(
                name='Verify real configuration tasks with tmpfs=' + str(enabled),
                hosts='localhost', connection='local', gather_facts=False,
                vars=dict(ovos_installer_method='virtualenv',
                          ovos_config_state_tmpfs_enabled=enabled,
                          ovos_config_logs_max_bytes=1000000,
                          ovos_config_logs_backup_count=1,
                          ovos_config_existing_conf={'content': base64.b64encode((('// keep operator logging settings\n# OVOS comment syntax\n' if commented else '') + json.dumps(existing)).encode()).decode()},
                          expected_logging=expected),
                tasks=[copy.deepcopy(preserve), {'name': 'Check preserved overrides and scope',
                       'ansible.builtin.assert': {'that': [
                           'ovos_config_existing_logs == {"max_bytes": 5000000, "path": "/logs/http://host/#keep"}',
                           'ovos_config_existing_logging == expected_logging']}}]))
        with tempfile.TemporaryDirectory() as directory:
            playbook = Path(directory) / 'verify.yml'
            playbook.write_text(yaml.safe_dump(plays, sort_keys=False))
            result = subprocess.run(['ansible-playbook', '-i', 'localhost,', str(playbook)],
                                    capture_output=True, text=True, timeout=40)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_containers_still_log_to_stdout(self):
        """Containers still log to stdout."""
        self.assertEqual(self.render(method='containers')['logs'], {'path': 'stdout'})

    def test_restore_excludes_legacy_logs_but_restores_scheduler(self):
        """Restore excludes legacy logs but restores scheduler."""
        with tempfile.TemporaryDirectory() as directory:
            source, target = Path(directory) / 'persist', Path(directory) / 'state'
            source.mkdir()
            target.mkdir()
            (source / 'gui.log.1').write_bytes(b'x' * 2000000)
            (source / 'skills.log').write_text('legacy log')
            (source / 'schedule.json').write_text('{"event": 1}')
            subprocess.run(['rsync', '-a', '--exclude=*.log', '--exclude=*.log.*', str(source) + '/', str(target) + '/'], check=True)
            self.assertEqual([p.name for p in target.iterdir()], ['schedule.json'])
            (target / 'schedule.json').write_text('{"event": 2}')
            self.assertEqual((source / 'gui.log.1').stat().st_size, 2000000)


if __name__ == '__main__':
    unittest.main()

"""Regression coverage for reclaiming full Mycroft state tmpfs on upgrades."""
import importlib.util
from pathlib import Path
import tempfile
import subprocess
import json
import base64
import copy
import sys
# The shell CI discovers every scripts/test_*.py without installing Ansible.
# Configuration integration tests run in the dedicated Ansible lint jobs.
try:
    import jinja2
    import yaml
    from ansible.plugins.filter.core import combine, to_json, to_bool
except ImportError:
    combine = None
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
            with patch.object(module.os, 'fsync', side_effect=OSError('disk full')):
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

    def test_nested_logs_are_archived_without_following_symlinks(self):
        """Nested custom log paths are preserved without traversing external paths."""
        with tempfile.TemporaryDirectory() as directory:
            state, archive, external = (Path(directory) / n for n in ('state', 'archive', 'external'))
            (state / 'logs').mkdir(parents=True)
            external.mkdir()
            (state / 'logs/skills.log').write_bytes(b'nested log')
            (external / 'private.log').write_bytes(b'outside state')
            (state / 'linked').symlink_to(external, target_is_directory=True)
            module.prepare_logs(state, archive, archive_all=True)
            self.assertEqual([p.read_bytes() for p in module.regular_files(archive)], [b'nested log'])
            self.assertEqual((external / 'private.log').read_bytes(), b'outside state')
            self.assertTrue((archive / 'logs').is_dir())

    def test_archive_budget_and_file_count_bound_repeated_runs(self):
        """Repeated boots retain bounded recent diagnostics, including oversized tails."""
        with tempfile.TemporaryDirectory() as directory:
            state, archive = Path(directory) / 'state', Path(directory) / 'archive'
            state.mkdir()
            for i in range(5):
                (state / 'skills.log').write_bytes(bytes([i]) * 4)
                module.prepare_logs(state, archive, archive_all=True, max_archive_bytes=8, max_archive_files=2)
                backups = list(module.regular_files(archive))
                self.assertLessEqual(len(backups), 2)
                self.assertLessEqual(sum(p.stat().st_size for p in backups), 8)
                self.assertIn(bytes([i]) * 4, [p.read_bytes() for p in backups])
            (state / 'skills.log').write_bytes(b'0123456789abcdef')
            module.prepare_logs(state, archive, archive_all=True, max_archive_bytes=8, max_archive_files=2)
            self.assertEqual([p.read_bytes() for p in module.regular_files(archive)], [b'89abcdef'])

    def test_failed_archival_clears_readiness_and_preserves_original(self):
        """A failed boot archive cannot leave a stale readiness marker enabling sync."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            state = root / 'state'
            state.mkdir()
            (state / 'skills.log').write_bytes(b'diagnostics')
            archive = root / 'not-a-directory'
            archive.write_text('occupied')
            ready = root / 'ready'
            ready.touch()
            result = subprocess.run([sys.executable, str(SCRIPT), str(state), str(archive),
                                     '--archive-all', '--ready-file', str(ready)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(ready.exists())
            self.assertEqual((state / 'skills.log').read_bytes(), b'diagnostics')
            self.assertIn(b'state sync remains disabled', result.stderr)

    def test_missing_state_does_not_enable_sync(self):
        """A missing or unreadable traversal must not be treated as an empty archive."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            ready = root / 'ready'
            ready.touch()
            result = subprocess.run([sys.executable, str(SCRIPT), str(root / 'missing'),
                                     str(root / 'archive'), '--archive-all',
                                     '--ready-file', str(ready)], capture_output=True)
            self.assertNotEqual(result.returncode, 0)
            self.assertFalse(ready.exists())


@unittest.skipIf(combine is None, "configuration integration requires Ansible; covered by Ansible CI")
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

    def test_uninstall_preserves_live_state_on_archival_or_sync_failure(self):
        """A failed archive or final sync stops uninstall before unmounting live state."""
        tasks = yaml.safe_load((SCRIPT.parents[4] / 'ansible/roles/ovos_storage_tuning/tasks/uninstall.yml').read_text())
        selected = [t for t in tasks if t['name'] in (
            'Check that archival and restore completed before syncing state',
            'Keep restored live state mounted if log archival failed',
            'Sync Mycroft state back to disk')]
        self.assertEqual(len(selected), 3)
        for archived, restored, sync_ok in ((False, True, True), (True, True, False),
                                            (True, True, True), (False, False, False)):
            with self.subTest(archived=archived, restored=restored, sync_ok=sync_ok):
                with tempfile.TemporaryDirectory() as directory:
                    root = Path(directory)
                    state = root / 'state'
                    state.mkdir()
                    for marker, present in (('.ovos-logs-archived', archived), ('.ovos-state-restored', restored)):
                        if present:
                            (state / marker).touch()
                    reached_unmount = root / 'reached-unmount'
                    plays = [{'hosts': 'all', 'connection': 'local', 'gather_facts': False,
                              'vars': {'ovos_storage_tuning_mycroft_state_dir': str(state),
                                       'ovos_storage_tuning_mycroft_state_persist_dir': str(root / 'persist'),
                                       'ovos_storage_tuning_rsync_path': '/usr/bin/true' if sync_ok else '/usr/bin/false'},
                              'tasks': selected + [{'ansible.builtin.file': {
                                  'path': str(reached_unmount), 'state': 'touch'}}]}]
                    playbook = root / 'verify.yml'
                    playbook.write_text(yaml.safe_dump(plays, sort_keys=False))
                    result = subprocess.run(['ansible-playbook', '-i', 'localhost,', str(playbook)],
                                            capture_output=True, text=True, timeout=40)
                    safe = not restored or (archived and sync_ok)
                    self.assertEqual(result.returncode == 0, safe, result.stdout + result.stderr)
                    self.assertEqual(reached_unmount.exists(), safe)

    def test_sync_is_gated_and_footprint_survives_failed_cleanup(self):
        """Service dependencies and markers guard sync; cleanup retains its retry baseline."""
        root = SCRIPT.parents[4]
        tasks = yaml.safe_load((root / 'ansible/roles/ovos_storage_tuning/tasks/install.yml').read_text())
        storage = next(t['block'] for t in tasks if t['name'] == 'Configure persistent tmpfs for Mycroft state')
        restore = next(t['ansible.builtin.copy']['content'] for t in storage if t['name'] == 'Install Mycroft state restore service')
        sync = next(t['ansible.builtin.copy']['content'] for t in storage if t['name'] == 'Install Mycroft state sync service')
        self.assertIn('RemainAfterExit=yes', restore)
        self.assertIn('ExecStartPre=-', restore)
        self.assertIn('--ready-file', restore)
        self.assertIn('ExecStartPost=/usr/bin/touch', restore)
        self.assertIn('Requires={{ ovos_storage_tuning_mycroft_state_restore_unit }}', sync)
        self.assertIn('After={{ ovos_storage_tuning_state_sync_after }} {{ ovos_storage_tuning_mycroft_state_restore_unit }}', sync)
        self.assertIn('ConditionPathExists={{ ovos_storage_tuning_mycroft_state_dir }}/.ovos-logs-archived', sync)
        self.assertIn('ConditionPathExists={{ ovos_storage_tuning_mycroft_state_dir }}/.ovos-state-restored', sync)
        uninstall = yaml.safe_load((root / 'ansible/roles/ovos_installer/tasks/uninstall.yml').read_text())
        names = [t['name'] for t in uninstall]
        self.assertLess(names.index('Remove the formulae this uninstall left unneeded'),
                        names.index('Remove OVOS service directories after tuning cleanup'))
        self.assertLess(names.index('Remove the formulae this uninstall left unneeded'),
                        names.index("Give back the user's home as the first install found it"))

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

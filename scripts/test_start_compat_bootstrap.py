"""Exercise compatibility bootstrap tasks without installing software on the host."""

import copy
import getpass
import grp
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import textwrap
import unittest

try:
    import yaml
except ImportError:
    yaml = None


ROOT = Path(__file__).resolve().parents[1]
ROLE = ROOT / "ansible/roles/ovos_virtualenv"


def executable(path: Path, contents: str) -> None:
    """Create a harmless executable inside the test's temporary directory."""
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("#!/bin/sh\n" + contents)
    path.chmod(0o755)


class HomebrewDependencyTests(unittest.TestCase):
    """Check the real dependency task against controlled Homebrew outcomes."""

    def test_dependency_install_outcomes(self) -> None:
        """Accept only success, an existing keg, or the specific link collision."""
        source = (ROLE / "tasks/packages.yml").read_text()
        task = source.split("- name: Install the formulae mpv's dependencies", 1)[1]
        script = textwrap.dedent(task.split("  ansible.builtin.shell: |\n", 1)[1]
                                 .split("  args:\n", 1)[0])
        for mode, expected in (("installed", 0), ("success", 0), ("link", 0),
                               ("download", 7), ("missing", 1)):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as directory:
                root = Path(directory)
                executable(root / "brew", '''
printf '%s\\n' "$*" >> "$TEST_CALLS"
case "$1" in
  list) [ "$TEST_MODE" = installed ] || [ -e "$TEST_KEG" ] ;;
  install)
    [ "$TEST_MODE" = missing ] || : > "$TEST_KEG"
    case "$TEST_MODE" in
      link|missing)
        echo 'The `brew link` step did not complete successfully'
        exit 1 ;;
      download) echo 'Download failed'; exit 7 ;;
    esac ;;
  tab) exit 0 ;;
  *) exit 99 ;;
esac
''')
                environment = dict(os.environ, PATH=f"{root}:/usr/bin:/bin",
                                   FORMULA="openssl@4", TEST_MODE=mode,
                                   TEST_CALLS=str(root / "calls"),
                                   TEST_KEG=str(root / "keg"))
                result = subprocess.run(["bash", "-c", script], env=environment,
                                        capture_output=True, text=True, timeout=10)
                self.assertEqual(result.returncode, expected, result.stdout + result.stderr)
                calls = (root / "calls").read_text()
                self.assertEqual("tab --no-installed-on-request openssl@4" in calls,
                                 mode in ("success", "link"))
                if mode == "installed":
                    self.assertNotIn("install --formula", calls)


@unittest.skipUnless(shutil.which("ansible-playbook") and yaml,
                     "Ansible and PyYAML are needed for role integration")
class UvSelectionTests(unittest.TestCase):
    """Run the real uv-selection tasks only, against disposable fake executables."""

    def run_selection(self, mode: str) -> None:
        """Prove the chosen uv wins and a user's own executable stays unchanged."""
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            home = root / "home"
            chosen = root / "checked/uv"
            user_uv = home / ".local/bin/uv"
            marker = root / "checked-called"
            executable(chosen, f'echo "uv 0.12.24"\nprintf called > "{marker}"\n')
            executable(user_uv, "echo 'user-owned uv'; exit 91\n")
            before = user_uv.read_bytes()
            executable(home / ".venvs/installer/bin/uv", "echo 'installer copy'; exit 92\n")
            link = home / ".ovos-installer/uv-bin/uv"
            if mode == "no-pin":
                link.parent.mkdir(parents=True)
                link.symlink_to(chosen)
            defaults = yaml.safe_load((ROLE / "defaults/main.yml").read_text())
            all_tasks = yaml.safe_load((ROLE / "tasks/venv.yml").read_text())
            start = next(i for i, task in enumerate(all_tasks)
                         if task["name"] == "Check that the user can run the uv setup.sh checked")
            end = next(i for i, task in enumerate(all_tasks)
                       if task["name"] == "Ensure ovos Python venv exists with requested Python")
            tasks = copy.deepcopy(all_tasks[start:end])
            # Only the selected real tasks run; become is unnecessary for a fixture
            # owned by this user. No package-manager or actual uv process can run.
            for task in tasks:
                task["become"] = False
            if mode == "no-pin":
                tasks = tasks[:5]
            variables = {
                "ovos_virtualenv_is_cleaning": False,
                "ovos_installer_user": getpass.getuser(),
                "ovos_installer_group": grp.getgrgid(os.getgid()).gr_name,
                "ovos_installer_user_home": str(home),
                "ovos_installer_uv_bin": "" if mode == "no-pin" else str(
                    chosen if mode == "valid" else root / "missing-uv"),
                "ovos_virtualenv_installer_venv_path": str(home / ".venvs/installer"),
                "ovos_virtualenv_venv_python": "3.11",
            }
            for key in ("ovos_virtualenv_uv_bin", "ovos_virtualenv_uv_link_dir",
                        "ovos_virtualenv_uv_exec_path", "ovos_virtualenv_uv_environment",
                        "ovos_virtualenv_uv_cache_dir"):
                variables[key] = defaults[key]
            playbook = root / "playbook.yml"
            playbook.write_text(yaml.safe_dump([{
                "hosts": "localhost", "gather_facts": False,
                "vars": variables, "tasks": tasks,
            }], sort_keys=False))
            config = root / "ansible.cfg"
            config.write_text("[defaults]\n")
            result = subprocess.run(
                ["ansible-playbook", "-i", "localhost,", "-c", "local", str(playbook),
                 "-e", f"ansible_python_interpreter={sys.executable}"],
                cwd=root, env=dict(os.environ, ANSIBLE_CONFIG=str(config),
                                   ANSIBLE_LOCAL_TEMP=str(root / "ansible-local"),
                                   ANSIBLE_REMOTE_TEMP=str(root / "ansible-remote")),
                capture_output=True, text=True, timeout=60,
            )
            self.assertEqual(result.returncode == 0, mode != "missing",
                             result.stdout + result.stderr)
            self.assertEqual(user_uv.read_bytes(), before)
            if mode == "valid":
                self.assertEqual(link.resolve(), chosen)
                self.assertTrue(marker.exists())
            elif mode == "no-pin":
                self.assertFalse(link.exists())
            else:
                self.assertFalse(link.exists())
                self.assertIn("Run setup.sh again", result.stdout)

    def test_checked_uv_wins_without_overwriting_user_uv(self) -> None:
        """A system uv is used even when the user's own uv deliberately refuses."""
        self.run_selection("valid")

    def test_unusable_uv_stops_before_any_other_uv_runs(self) -> None:
        """An invalid explicit pin cannot silently fall back to another executable."""
        self.run_selection("missing")

    def test_no_pin_removes_previous_selection(self) -> None:
        """Standalone role reuse cannot accidentally retain an earlier uv choice."""
        self.run_selection("no-pin")


if __name__ == "__main__":
    unittest.main()

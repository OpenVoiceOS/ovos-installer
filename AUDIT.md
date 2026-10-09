Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Keep compatibility report permission tests portable.

# Compatibility bootstrap review

- Fixed the wrong-uv selection and user-file overwrite in the [virtualenv tasks](ansible/roles/ovos_virtualenv/tasks/venv.yml). `UvSelectionTests` in [test_start_compat_bootstrap.py](scripts/test_start_compat_bootstrap.py) passes all three disposable Ansible scenarios.
- Backported the OpenSSL dependency preparation in [packages.yml](ansible/roles/ovos_virtualenv/tasks/packages.yml). `HomebrewDependencyTests` passes five outcomes, rejecting download failures and missing kegs.
- Six focused [virtualenv BATS tests](tests/bats/virtualenv.bats) pass, including inaccessible uv and non-file fallback.
- The compatibility branch does not contain all current upstream fixes. No complete device installation or real Homebrew package installation was performed; these checks establish bootstrap behavior only.

- Complete `python3 -m unittest discover -s scripts -p "test_*.py" -q` passes: 95 tests. The sanitizer tests use the existing unittest runner, matching upstream PR666. Thirty-four Mac/report/error BATS regressions also pass.

- The [error-report test fixture](tests/bats/error_report.bats) no longer relies on Linux-specific stat flags. Twenty-five report/error BATS cases pass; a regression proves actual 0600 and 0644 are read while shell stat is unavailable.

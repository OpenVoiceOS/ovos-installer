Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Keep compatibility report permission tests portable.

# Compatibility bootstrap questions

## Why retain this branch?

It preserves the wizard’s existing Mac targets while backporting selected bootstrap fixes.
See [automation](docs/automation.md) and [`resolve_installer_uv`](utils/common.sh).

## Will installation overwrite my own uv?

The [virtualenv role](ansible/roles/ovos_virtualenv/tasks/venv.yml) selects the checked installer executable in its own directory and preserves an existing `~/.local/bin/uv`.

## Does the report permission test require GNU stat?

No. [The fixture](tests/bats/error_report.bats) uses Python and verifies both private and non-private modes without shell stat. Production upload permissions are unchanged.

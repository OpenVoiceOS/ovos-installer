Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Record the tested compatibility bootstrap backport.

# Compatibility bootstrap questions

## Why retain this branch?

It preserves the wizard’s existing Mac targets while backporting selected bootstrap fixes.
See [automation](docs/automation.md) and [`resolve_installer_uv`](utils/common.sh).

## Will installation overwrite my own uv?

The [virtualenv role](ansible/roles/ovos_virtualenv/tasks/venv.yml) selects the checked installer executable in its own directory and preserves an existing `~/.local/bin/uv`.

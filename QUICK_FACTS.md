Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Record the tested compatibility bootstrap backport.

# Compatibility branch facts

| Field | Value |
|---|---|
| Repository | OpenVoiceOS/ovos-installer |
| Version | Git revision; compatibility base `6ffd4650` |
| Entrypoints | `installer.sh`, `setup.sh`; no Python plugin entry points |
| Branch | `fix/start-error-report-compat` |
| Bootstrap | `utils/common.sh:resolve_installer_uv` selects the executable passed to the virtualenv role |
| Mac support | Existing compatibility checks are unchanged |
| Regression coverage | `scripts/test_start_compat_bootstrap.py`, `tests/bats/virtualenv.bats` |

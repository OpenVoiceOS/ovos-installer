Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Address PR 666 reporting review and retain upstream terminal fixes.

# Quick facts

| Field | Value |
| --- | --- |
| Package/repository | `OpenVoiceOS/ovos-installer`; shell/Ansible application, not a Python distribution |
| Version | Checked-out Git commit; `setup.sh` exports `INSTALLER_VERSION` from `git rev-parse --short=8 HEAD` |
| Entry points | `installer.sh` bootstrap; `setup.sh` orchestration; no Python package/plugin entry points |
| Error reports | `OVOS_INSTALLER_REPORT_FD=3` optionally receives only a validated paste URL after an authorized upload; no log contents; see `utils/common.sh:report_upload_url()` |
| Upload consent | Standalone asks through `on_error()`; refusal, EOF and noninteractive sessions do not upload |
| Wizard reports | Exact `OVOS_INSTALLER_AUTO_REPORT=1` plus writable FD 3 enables a filtered, bounded, current-run HTTPS report without prompting; no raw fallback |
| Report size | Complete input must fit within 1.5 MB or a smaller configured limit; oversized logs stay local |
| Satellite redaction | `setup.sh` retains key/password values without tracing; `upload_wizard_logs()` explicitly supplies retained/current shell values |
| Report cleanup | Upload-local EXIT/INT/TERM/HUP traps remove private staging files without replacing caller traps |
| Speech selection | `speech_engine: public` or `local`; local includes public fallback |
| Local eligibility | Alpha, supported audio profile, capable 64-bit hardware and at least 7680 MiB RAM; see `utils/speech.sh` |
| Failed recognition | Failed or empty local recognition may send the recording to public servers |
| Failed model setup | The affected recognition or synthesis component uses public speech |
| Rejected STT downloads | New caches are removed after timeout, unsuccessful probe or excessive measured memory; existing caches are preserved |
| Terminal status | `➤`/`⚠`/drinks where the terminal draws them; `>`/`WARNING:` on the Linux console, dumb terminals, non-UTF-8 locales; `OVOS_INSTALLER_ASCII=1` or `0` overrides |
| Test command | `pytest -q scripts/test_speech_setup.py scripts/test_local_speech_bus.py` |

Source: [`first_working()`, `forget_model()` and `with_public_fallback()`](ansible/roles/ovos_config/files/speech_setup.py),
[`SpeechSetupTest`](scripts/test_speech_setup.py), [documentation](docs/index.md).

Report permission regression: [error_report.bats](tests/bats/error_report.bats) inspects real file modes through Python, with both private and non-private fixtures; it does not depend on GNU/BSD `stat` flags.

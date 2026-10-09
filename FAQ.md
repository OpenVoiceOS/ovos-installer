Last Edit: Codex (GPT-6) - 2026-10-08 - Motive: Explain automatic wizard reports and standalone consent.

# Frequently asked questions

## Can a launcher show the error-report link?

Yes. With `OVOS_INSTALLER_REPORT_FD=3` and descriptor 3 already open,
[`on_error()`](utils/common.sh) reports the validated paste URL. It never sends
log contents through that descriptor. The wizard sets `OVOS_INSTALLER_AUTO_REPORT=1`
to upload automatically without a Terminal question. This path filters credentials
from the current run's bounded log and uses verified HTTPS. It skips reporting if
the descriptor, sanitizer or upload is unavailable; there is no raw-log fallback.

Standalone installations still ask before uploading. See [the contract](docs/automation.md#environment-variables),
[handoff tests](tests/bats/error_report.bats) and
[`sanitize()` tests](scripts/test_sanitize_error_log.py).

## Does local speech keep every recording offline?

No. Failed or empty recognition sends that recording to public servers. If a
local recognizer or voice cannot run during setup, that component uses public
speech instead; the installer reports this. See [scenario settings](docs/automation.md#scenario-settings)
and [`with_public_fallback()`](ansible/roles/ovos_config/files/speech_setup.py).

## What happens to a failed speech-model download?

`first_working()` removes a rejected recognizer cache if the current run created
it, including after a crash or timeout. `forget_model()` preserves directories
that existed before the run. A successful retry keeps its working download.
See [implementation](ansible/roles/ovos_config/files/speech_setup.py) and
[`SpeechSetupTest.test_failed_probes_remove_only_new_downloads()`](scripts/test_speech_setup.py).

## Do the automated tests install OVOS or download models?

The speech setup unit tests use stub plugins and real child processes. They
exercise failure, timeout, retention and fallback behavior without an actual
installation. Real-device timing remains a separate validation step.

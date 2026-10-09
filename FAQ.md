Last Edit: Codex (GPT-6) - 2026-10-08 - Motive: Explain optional error-report sharing with launchers.

# Frequently asked questions

## Can a launcher show the error-report link?

Yes. With `OVOS_INSTALLER_REPORT_FD=3` and descriptor 3 already open,
[`on_error()`](utils/common.sh) reports the validated paste URL after the person
agrees to upload the log. It never sends log contents through this descriptor.
Refusal, no terminal or a failed upload leaves the launcher without a URL; the
Terminal still explains the failure. See [the contract](docs/automation.md#environment-variables)
and [consent and URL tests](tests/bats/error_report.bats).

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

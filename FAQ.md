Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Address PR 666 reporting review and retain upstream terminal fixes.

# Frequently asked questions

## Why might a wizard failure have no report link?

Automatic reporting skips logs whose complete source exceeds 1.5 MB (or a
smaller configured limit). Cutting off the beginning before filtering could
expose a private-key fragment. The local log remains available. It also skips
unavailable descriptors, sanitizers and failed uploads without sending raw logs.
See [`bounded_log()`](scripts/sanitize_error_log.py) and
[the reporting contract](docs/automation.md#environment-variables).

## Are satellite credentials removed from automatic reports?

The sanitizer receives satellite key/password values explicitly, including
shell-only values and copies retained by `setup.sh`. Tests verify removal even
without field names in [the uploaded payload](tests/bats/error_report.bats).
Filtering still cannot guarantee that every possible secret format is recognized.

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

## Why did the installer show empty squares before its messages?

The status arrow, warning sign and drink emoji were missing from some terminal
fonts. The installer now shows them only where the terminal can draw them, and
`>` and `WARNING:` elsewhere: on the Linux text console (a Raspberry Pi or a
Mark II on its own screen), a dumb or serial terminal, or a locale that is not
UTF-8. See [`set_status_marks()`](utils/common.sh).

A desktop terminal whose font lacks them can still show squares, because a
script cannot see the font. Run the installer with `OVOS_INSTALLER_ASCII=1` for
plain text. The change needs an installer version containing this fix.

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

## Why did the report permission test fail on macOS?

The test fixture used Linux-specific `stat -c` flags. The production upload file still uses mode 0600. [The corrected fixture](tests/bats/error_report.bats) uses Python to read permissions and also verifies that a mode 0644 fixture is recognized.

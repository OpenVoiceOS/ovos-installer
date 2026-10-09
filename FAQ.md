Last Edit: Claude (Opus 5.5) - 2026-10-09 - Motive: Explain when the status symbols are shown.

# Frequently asked questions

## Why did the installer show empty squares before its messages?

The status arrow, warning sign and drink emoji were missing from some terminal
fonts. The installer now shows them only where the terminal can draw them, and
`>` and `WARNING:` elsewhere: on the Linux text console (a Raspberry Pi or a
Mark II on its own screen), a dumb or serial terminal, or a locale that is not
UTF-8. See [`set_status_marks()`](utils/common.sh). The arrow is now `→` rather than
`➤`, which almost no monospace font has.

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

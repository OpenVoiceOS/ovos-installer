Last Edit: Codex (GPT-6) - 2026-10-08 - Motive: Explain terminal-safe status messages.

# Frequently asked questions

## Why did the installer show empty squares before its messages?

The old status arrow and drink emoji were missing from some terminal fonts.
Progress now uses `>` and warnings use `WARNING:` in
[`detect_cpu_instructions()`](utils/common.sh),
[`detect_local_speech_support()`](utils/speech.sh), and [setup](setup.sh).
The change needs an installer version containing this fix; an already running
installation keeps its existing output.

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

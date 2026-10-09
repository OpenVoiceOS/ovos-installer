Last Edit: Claude (Opus 5.5) - 2026-10-09 - Motive: Keep the status symbols where the terminal can draw them.

# Audit

## 2026-10-08 — Terminal status glyphs

- **Fixed:** status arrows, warning symbols and drink emoji rendered as empty
  boxes on terminals without those glyphs.
  [`set_status_marks()`](utils/common.sh) now chooses them once: `→`, `⚠` and
  the drinks where the terminal can draw them, `>` and `WARNING:` on the Linux
  text console, dumb or serial terminals, and locales that are not UTF-8. The
  user's own locale is read before [setup](setup.sh) replaces it.
  `OVOS_INSTALLER_ASCII=1` forces plain text and `=0` the symbols.
- **Limit:** a shell cannot see the font. A UTF-8 desktop terminal whose font
  lacks a glyph still shows a box; `OVOS_INSTALLER_ASCII=1` is the way out.
- **Verification:** BATS tests for each terminal case, ShellCheck, and real
  output under `TERM=linux`, `TERM=dumb`, `LANG=C` and a UTF-8 xterm. No
  physical-device installation was performed.

## 2026-10-08 — PR 648 follow-up

- **Fixed: rejected STT downloads survived failed probes.** Timeout and unsuccessful
  process exits now call `forget_model()` in
  [`first_working()`](ansible/roles/ovos_config/files/speech_setup.py).
  [`SpeechSetupTest.test_failed_probes_remove_only_new_downloads()`](scripts/test_speech_setup.py)
  reproduces both failures, checks that existing caches survive and verifies the
  successful fallback's files remain. The new assertions failed before the fix.
- **Fixed: local-speech privacy wording.** The selection and summary disclose
  public fallback. The speech screen and [automation guide](docs/automation.md)
  describe failed/empty recognition uploads and public speech when a local model
  cannot run; they make no fully offline promise.
- **Verification:** `pytest -q scripts/test_speech_setup.py scripts/test_local_speech_bus.py`
  passes **28 tests and 4 subtests**. **99 BATS tests pass with no skips**, including
  all locales, navigation, real whiptail and speech Ansible tasks. Ruff, ShellCheck,
  the offline contract checker and `git diff --check` pass. Display verification
  is recorded in [the maintenance report](MAINTENANCE_REPORT.md).
- **Outstanding integration evidence:** the full matrix for reviewed head
  `f10c2d5f` failed two container scenarios with skill-ID errors before completing
  all speech checks. See [run 37778575537](https://github.com/OpenVoiceOS/ovos-installer/actions/runs/37778575537).
  The affected launch IDs are not changed by this patch. A new matrix run and
  Raspberry Pi 5 timing are required before claiming complete device coverage.

This is a focused review of the changed paths, not a whole-repository security audit.

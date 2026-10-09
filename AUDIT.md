Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Address PR 666 reporting review and retain upstream terminal fixes.

# Audit

## 2026-10-09 — PR 666 review fixes

- **Fixed:** [`setup.sh`](setup.sh) retains satellite values outside the Home
  Assistant/LLM condition, with tracing off. `upload_wizard_logs()` in
  [`utils/common.sh`](utils/common.sh) passes retained or current shell values
  explicitly to the sanitizer. The field-free satellite fixture in
  [`error_report.bats`](tests/bats/error_report.bats) covers exported, unexported
  and retained credentials through the actual failure/upload handoff.
- **Fixed:** [`bounded_log()`](scripts/sanitize_error_log.py) rejects oversized
  sources and concurrent growth instead of selecting a tail inside a multiline
  secret. The oversized-private-key upload regression failed before this fix;
  now no request or URL is produced and the local log remains.
- **Fixed:** upload-local EXIT/INT/TERM/HUP traps remove the private report file
  without replacing caller traps. [`error_report_cleanup.bats`](tests/bats/error_report_cleanup.bats)
  reproduces a leftover file on the old code and covers normal returns, errors
  and interruptions while sanitizing or uploading.
- Validation: **39 BATS tests**, **42 pytest tests and 28 subtests** pass;
  ShellCheck, Ruff, Bash syntax and whitespace checks pass. Merged the upstream
  terminal-symbol fix and retained `on_error()` for Ansible failures.
- Limits: oversized automatic reports are skipped; filtering is not anonymity.
  No network log uploads or physical-device installation were performed.

## 2026-10-08 — Automatic wizard failure reports

- [`on_error()` and `upload_wizard_logs()`](utils/common.sh) require explicit
  wizard flags and a writable descriptor before an automatic upload. The default
  still asks; invalid flags and EOF cannot authorize a standalone upload.
- Only the current run's fresh installer log is read; persistent prior Ansible
  logs are excluded. [`sanitize()`](scripts/sanitize_error_log.py) bounds input and
  removes known values and common credential syntax. The temporary payload is
  mode 0600 and removed after upload; curl ignores configuration and verifies TLS
  to the fixed paste origin with no redirect or insecure retry.
- Failures of descriptor checks, filtering, uploads and URL validation retain the
  installation failure and never fall back to raw logs. [BATS coverage](tests/bats/error_report.bats)
  uses mocked uploads; [Python coverage](scripts/test_sanitize_error_log.py) checks
  redaction, unsafe files, oversized input and malformed-log performance.
- Validation: 55 focused BATS passes with one existing sound-detection skip;
  54 pytest passes and four subtests; ShellCheck, Bash syntax and diff checks pass.
- Limits: filtering cannot guarantee anonymous logs. The standalone consented
  uploader retains its existing transport behavior; this change hardens only the
  newly automatic path. No real upload or device installation was run.

## 2026-10-08 — Consented error-report handoff

- **Fixed:** the Ansible failure branch in [`setup.sh`](setup.sh) now uses
  `on_error()` instead of uploading logs without asking. `ask_optin()` treats EOF
  as refusal. [`error_report.bats`](tests/bats/error_report.bats) executes the real
  failure branch with yes/no answers and verifies upload calls and report bytes.
- `report_upload_url()` in [`utils/common.sh`](utils/common.sh) accepts only the
  fixed paste origin and bounded ASCII ID. It writes only after consent and only
  to explicitly enabled FD 3. Tests cover malicious URLs, unavailable descriptors,
  failed uploads and noninteractive refusal; no actual upload occurs.
- Validation: 53 BATS passes, one existing sound-detection skip; 28 pytest passes
  and 4 subtests; changed-shell ShellCheck and whitespace checks pass. This covers
  the installer contract, not the separate launcher's live deployment.

## 2026-10-08 — Terminal status glyphs

- **Fixed:** status arrows, warning symbols and drink emoji rendered as empty
  boxes on terminals without those glyphs.
  [`set_status_marks()`](utils/common.sh) now chooses them once: `➤`, `⚠` and
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

## 2026-10-09 — macOS report fixture correction

`tests/bats/error_report.bats:setup` used GNU-only `stat -c`, producing an empty mode on macOS. The fixture now uses Python `os.stat()` and `stat.S_IMODE()`; the new regression verifies 0600 and 0644 while shell `stat` is unavailable. Twenty-five report/error BATS cases and ten sanitizer pytest methods pass. Production upload permissions remain unchanged.

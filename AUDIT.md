Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Record portable permission checks in report test fixtures.

# Audit

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

`tests/bats/error_report.bats:setup` used GNU-only `stat -c`, producing an empty mode on macOS. The fixture now uses Python `os.stat()` and `stat.S_IMODE()`; the new regression verifies 0600 and 0644 while shell `stat` is unavailable. Twenty-five report/error BATS cases and nine sanitizer pytest methods pass. Production upload permissions remain unchanged.

Last Edit: Codex (GPT-6) - 2026-10-08 - Motive: Record terminal status symbol fix and validation.

# Maintenance report

## 2026-10-08 — Readable terminal status

Replaced decorative status arrows with `>`, warning symbols with `WARNING:`,
and removed drink emoji from the Ansible startup message. This covers
[setup](setup.sh), [common helpers](utils/common.sh),
[speech detection](utils/speech.sh), and [cancellation](tui/navigation.sh).
The existing [reboot ordering test](tests/bats/code_quality.bats#L3693) now
recognizes the updated startup message. Installer control flow is unchanged.

Validation: 134 focused BATS tests, 16 pytest contract tests, ShellCheck,
`git diff --check`, and ASCII rendering checks for CPU/speech/startup output
under `LC_ALL=C` and `C.UTF-8` with `TERM=dumb` pass.

### Transparency Report

- **AI Model:** GPT-6 (Codex).
- **Actions Taken:** traced screenshot symbols to shell messages, replaced the
  decorative glyphs, updated the existing test matcher, and ran validation.
- **Oversight:** user identified the rendering defect; automated and AI review
  performed. No physical-device installation was run.

## 2026-10-08 — PR 648 review fixes

- `first_working()` in [speech_setup.py](ansible/roles/ovos_config/files/speech_setup.py)
  now cleans newly created recognizer caches after timeout and unsuccessful
  probes, using the existing protection for caches present before the run.
- [Speech setup regressions](scripts/test_speech_setup.py) cover new/existing
  caches under both failure paths, public fallback and a same-model retry that
  succeeds. The new failure assertions were run against the old behavior first.
- Speech selection, summary and documentation now state that local speech has a
  public fallback. All 14 locale catalogs and their generated screens are updated.
- Added a [documentation index](docs/index.md) and the workspace-required
  maintenance references without changing runtime dependencies or installer pins.

### Verification

- Pytest: **28 passed, 4 subtests passed** for speech setup and bus checks.
- BATS: **99 passed, none skipped**, covering speech/Ansible integration,
  navigation, all 14 locales, real whiptail and dialog sizing.
- Real English and French speech screens checked at 80×24 and 90×32; disclosures,
  choices and navigation buttons remain visible.
- Repository-wide Ruff, ShellCheck on changed shell screens, offline contract
  checks, Markdown local links and diff whitespace checks pass.
- No real-device installer or model downloads were run locally.

### Transparency Report

- **AI Model:** GPT-6 (Codex).
- **Actions Taken:** reproduced review findings, changed cleanup and localized
  disclosure, added regression assertions, reviewed the diff, ran tests and wrote
  these maintenance notes.
- **Oversight:** user requested the fixes; automated and AI review were performed.
  No human translation sign-off or physical Raspberry Pi test is claimed.

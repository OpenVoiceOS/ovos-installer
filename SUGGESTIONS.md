Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Record portable permission checks in report test fixtures.

# Suggestions

| Problem or opportunity | Proposed action | Expected impact |
| --- | --- | --- |
| Automatic report filtering covers known values and common credential forms, not every possible application output | Add regression fixtures when new credential formats appear; keep failure reporting fail-closed | Reduces unintended credential disclosure; see [sanitizer tests](scripts/test_sanitize_error_log.py) |
| Container end-to-end validation was interrupted by skill-ID errors | Resolve the image/package mismatch and rerun the exhaustive matrix, including ARM64 local speech | Confirms the installed services actually answer |
| CI runners do not establish Pi 5 latency | Install on a Pi 5 with 8 GB and time several real utterances, including an update | Confirms the advertised hardware floor and user experience |
| Localized fallback wording needs human review | Ask native speakers to review the 14 speech screens, especially Kabyle, Basque and Hindi | Makes recording uploads and public fallback understandable |

Relevant evidence: [audit](AUDIT.md),
[`SpeechSetupTest`](scripts/test_speech_setup.py) and
[`first_working()`](ansible/roles/ovos_config/files/speech_setup.py).

For future cross-platform permission fixtures, use Python’s `os.stat()` rather than shell-specific `stat` flags. The [report fixture regression](tests/bats/error_report.bats) covers both 0600 and 0644; this reduces false macOS CI failures without weakening the permission assertion.

Last Edit: Claude (Opus 5.5) - 2026-10-09 - Motive: Record the terminal-font compatibility decision.

# Suggestions

Status symbols are shown only where the terminal is likely to draw them; UTF-8
locale support does not prove glyph availability, so `OVOS_INSTALLER_ASCII=1`
remains the escape hatch. Keep every message readable from its words alone, so
the plain-text marks lose nothing. See [`set_status_marks()`](utils/common.sh).

| Problem or opportunity | Proposed action | Expected impact |
| --- | --- | --- |
| Container end-to-end validation was interrupted by skill-ID errors | Resolve the image/package mismatch and rerun the exhaustive matrix, including ARM64 local speech | Confirms the installed services actually answer |
| CI runners do not establish Pi 5 latency | Install on a Pi 5 with 8 GB and time several real utterances, including an update | Confirms the advertised hardware floor and user experience |
| Localized fallback wording needs human review | Ask native speakers to review the 14 speech screens, especially Kabyle, Basque and Hindi | Makes recording uploads and public fallback understandable |

Relevant evidence: [audit](AUDIT.md),
[`SpeechSetupTest`](scripts/test_speech_setup.py) and
[`first_working()`](ansible/roles/ovos_config/files/speech_setup.py).

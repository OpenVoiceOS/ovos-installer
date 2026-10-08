Last Edit: Codex (GPT-6) - 2026-10-08 - Motive: Record remaining local-speech validation opportunities.

# Suggestions

| Problem or opportunity | Proposed action | Expected impact |
| --- | --- | --- |
| Container end-to-end validation was interrupted by skill-ID errors | Resolve the image/package mismatch and rerun the exhaustive matrix, including ARM64 local speech | Confirms the installed services actually answer |
| CI runners do not establish Pi 5 latency | Install on a Pi 5 with 8 GB and time several real utterances, including an update | Confirms the advertised hardware floor and user experience |
| Localized fallback wording needs human review | Ask native speakers to review the 14 speech screens, especially Kabyle, Basque and Hindi | Makes recording uploads and public fallback understandable |

Relevant evidence: [audit](AUDIT.md),
[`SpeechSetupTest`](scripts/test_speech_setup.py) and
[`first_working()`](ansible/roles/ovos_config/files/speech_setup.py).

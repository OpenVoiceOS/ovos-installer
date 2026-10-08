#!/usr/bin/env bash
CONTENT="
Bijna klaar. Een korte samenvatting:

    - Omgeving:       ${METHOD:-}
    - Versie:         ${CHANNEL:-}
    - Profiel:        ${PROFILE:-}
    - Skills:         ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Extra skills:   ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - Home Assistant: ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM:            ${LLM_SUMMARY_STATE:-}
    - Spraak:         ${SPEECH_SUMMARY_STATE:-}
    - Tuning:         ${TUNING_SUMMARY_STATE:-}

De beslissingen die zijn genomen tijdens het installatieproces van OpenVoice OS zijn zorgvuldig gemaakt om ons systeem aan te passen aan je individuele behoeften en voorkeuren.

Zijn de instellingen zo in orde? Zo niet, kies ${BACK_BUTTON:-} om terug te gaan en wijzigingen te maken.
"
TITLE="OpenVoice OS Installatie - Samenvatting"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"
SUMMARY_SPEECH_LOCAL="op deze machine met openbare servers als reserve"
SUMMARY_SPEECH_PUBLIC="openbare servers"
SUMMARY_SPEECH_PUBLIC_HARDWARE="openbare servers (lokaal: Pi 5 met 8 GB of beter)"
SUMMARY_SPEECH_PUBLIC_SETUP="openbare servers (lokaal hier niet beschikbaar)"
SUMMARY_SPEECH_UNUSED="niet gebruikt door dit profiel"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION SUMMARY_SPEECH_LOCAL SUMMARY_SPEECH_PUBLIC SUMMARY_SPEECH_PUBLIC_HARDWARE SUMMARY_SPEECH_PUBLIC_SETUP SUMMARY_SPEECH_UNUSED

#!/usr/bin/env bash
CONTENT="
Fast fertig. Eine kurze Zusammenfassung:

    - Umgebung:       ${METHOD:-}
    - Version:        ${CHANNEL:-}
    - Profil:         ${PROFILE:-}
    - Skills:         ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Extra-Skills:   ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - Home Assistant: ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM:            ${LLM_SUMMARY_STATE:-}
    - Sprache:        ${SPEECH_SUMMARY_STATE:-}
    - Tuning:         ${TUNING_SUMMARY_STATE:-}

Die Entscheidungen, die während des Installationsprozesses von Open Voice OS getroffen werden, wurden sorgfältig abgewogen, um unser System an Ihre individuellen Bedürfnisse und Vorlieben anzupassen.

Stimmen die Einstellungen? Falls nicht, wählen Sie ${BACK_BUTTON:-}, um zurückzugehen und Änderungen vorzunehmen.
"
TITLE="Open Voice OS Installation - Zusammenfassung"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"
SUMMARY_SPEECH_LOCAL="auf diesem Rechner"
SUMMARY_SPEECH_PUBLIC="öffentliche Server"
SUMMARY_SPEECH_PUBLIC_HARDWARE="öffentliche Server (lokal: Pi 5 mit 8 GB oder besser)"
SUMMARY_SPEECH_PUBLIC_SETUP="öffentliche Server (lokal: alpha und virtualenv)"
SUMMARY_SPEECH_UNUSED="von diesem Profil nicht genutzt"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION SUMMARY_SPEECH_LOCAL SUMMARY_SPEECH_PUBLIC SUMMARY_SPEECH_PUBLIC_HARDWARE SUMMARY_SPEECH_PUBLIC_SETUP SUMMARY_SPEECH_UNUSED

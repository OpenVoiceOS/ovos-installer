#!/usr/bin/env bash
CONTENT="
Abbiamo quasi finito. Qui c'è un riassunto delle opzioni scelte per installare Open Voice OS:

    - Distribuzione:    ${METHOD:-}
    - Versione:         ${CHANNEL:-}
    - Profilo:          ${PROFILE:-}
    - Competenze:       ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Competenze extra: ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - Home Assistant:   ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM:              ${LLM_SUMMARY_STATE:-}
    - Voce:             ${SPEECH_SUMMARY_STATE:-}
    - Ottimizzazione:   ${TUNING_SUMMARY_STATE:-}

Le decisioni prese durante il processo di installazione di Open Voice OS sono state attentamente valutate per personalizzare il nostro sistema in base alle tue esigenze e preferenze individuali.

Le impostazioni sono corrette? In caso contrario, seleziona ${BACK_BUTTON:-} per tornare indietro e apportare modifiche.
"
TITLE="Installazione di Open Voice OS - Riassunto"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"
SUMMARY_SPEECH_LOCAL="su questa macchina con server pubblici di riserva"
SUMMARY_SPEECH_PUBLIC="server pubblici"
SUMMARY_SPEECH_PUBLIC_HARDWARE="server pubblici (locale: Pi 5 con 8 GB o superiore)"
SUMMARY_SPEECH_PUBLIC_SETUP="server pubblici (locale non disponibile qui)"
SUMMARY_SPEECH_UNUSED="non usata da questo profilo"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION SUMMARY_SPEECH_LOCAL SUMMARY_SPEECH_PUBLIC SUMMARY_SPEECH_PUBLIC_HARDWARE SUMMARY_SPEECH_PUBLIC_SETUP SUMMARY_SPEECH_UNUSED

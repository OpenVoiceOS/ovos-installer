#!/usr/bin/env bash
CONTENT="
Gairebé heu acabat, aquí teniu un resum de les opcions que heu triat en instal·lar l'Open Voice OS:

    - Mètode:           ${METHOD:-}
    - Versió:           ${CHANNEL:-}
    - Perfil:           ${PROFILE:-}
    - Habilitats:       ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Habilitats extra: ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - Home Assistant:   ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM:              ${LLM_SUMMARY_STATE:-}
    - Afinació:         ${TUNING_SUMMARY_STATE:-}

Les opcions seleccionades durant el procés d'instal·lació de l'Open Voice OS s'han considerat acuradament per a adaptar el nostre sistema a les vostres necessitats i preferències úniques.

Us sembla correcte aquest resum? Si no, selecciona ${BACK_BUTTON:-} (o prem ESC) per tornar enrere i fer canvis.
"
TITLE="Instal·lació de l'Open VoiceOS - Resum"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION

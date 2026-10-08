#!/usr/bin/env bash
CONTENT="
Estás a piques de rematar. Aquí tes un resumo das opcións que escolliches para instalar Open Voice OS:

    - Método:                 ${METHOD:-}
    - Versión:                ${CHANNEL:-}
    - Perfil:                 ${PROFILE:-}
    - Habilidades:            ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Habilidades adicionais: ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - Home Assistant:         ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM:                    ${LLM_SUMMARY_STATE:-}
    - Voz:                    ${SPEECH_SUMMARY_STATE:-}
    - Axustes:                ${TUNING_SUMMARY_STATE:-}

As decisións tomadas durante a instalación de Open Voice OS foron coidadosamente pensadas para adaptar o noso sistema ás túas necesidades e preferencias.

É correcto este resumo? Se non, selecciona ${BACK_BUTTON:-} para volver atrás e facer cambios.
"
TITLE="Instalación de Open Voice OS - Recapitulación"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"
SUMMARY_SPEECH_LOCAL="neste equipo con servidores públicos de respaldo"
SUMMARY_SPEECH_PUBLIC="servidores públicos"
SUMMARY_SPEECH_PUBLIC_HARDWARE="servidores públicos (local: Pi 5 de 8 GB ou mellor)"
SUMMARY_SPEECH_PUBLIC_SETUP="servidores públicos (local non dispoñible aquí)"
SUMMARY_SPEECH_UNUSED="este perfil non a usa"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION SUMMARY_SPEECH_LOCAL SUMMARY_SPEECH_PUBLIC SUMMARY_SPEECH_PUBLIC_HARDWARE SUMMARY_SPEECH_PUBLIC_SETUP SUMMARY_SPEECH_UNUSED

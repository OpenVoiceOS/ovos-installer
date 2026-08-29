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
    - Axustes:                ${TUNING_SUMMARY_STATE:-}

As decisións tomadas durante a instalación de Open Voice OS foron coidadosamente pensadas para adaptar o noso sistema ás túas necesidades e preferencias.

É correcto este resumo? Se non, selecciona ${BACK_BUTTON:-} (ou preme ESC) para volver atrás e facer cambios.
"
TITLE="Instalación de Open Voice OS - Recapitulación"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION

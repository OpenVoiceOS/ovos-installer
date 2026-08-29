#!/usr/bin/env bash
CONTENT="
¡Ya casi has terminado! Aquí tienes un resumen de las opciones que has elegido para instalar Open Voice OS:

- Method: ${METHOD:-}
- Version: ${CHANNEL:-}
- Profile: ${PROFILE:-}
- Skills: ${FEATURE_SKILLS_SUMMARY_STATE:-}
- Tuning: ${TUNING_SUMMARY_STATE:-}

Las decisiones que has tomado durante el proceso de instalación de Open Voice OS han sido cuidadosamente consideradas para adaptar el sistema a tus necesidades y preferencias.

¿Este resumen es correcto? Si no, selecciona ${BACK_BUTTON:-} (o pulsa ESC) para volver atrás y hacer cambios.
"
TITLE="Instalación de Open Voice OS - Resumen"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION

#!/usr/bin/env bash
CONTENT="
¡Ya casi has terminado! Aquí tienes un resumen de las opciones que has elegido para instalar Open Voice OS:

- Method: $METHOD
- Version: $CHANNEL
- Profile: $PROFILE
- Skills: $FEATURE_SKILLS
- Tuning: $TUNING

Las decisiones que has tomado durante el proceso de instalación de Open Voice OS han sido cuidadosamente consideradas para adaptar el sistema a tus necesidades y preferencias.

¿Este resumen es correcto? Si no, selecciona $BACK_BUTTON (o pulsa ESC) para volver atrás y hacer cambios.
"
TITLE="Instalación de Open Voice OS - Resumen"

export CONTENT TITLE

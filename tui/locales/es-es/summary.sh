#!/bin/env bash

CONTENT="
Casi terminado. Un breve resumen:

    - Entorno:       $METHOD
    - Version:       $CHANNEL
    - Perfile:       $PROFILE
    - GUI:           $FEATURE_GUI
    - Skills:        $FEATURE_SKILLS
    - Sintonización: $TUNING

Las decisiones tomadas durante el proceso de instalación de Open Voice OS han sido cuidadosamente consideradas para adaptar nuestro sistema a sus necesidades y preferencias individuales.

¿Son correctos los ajustes?
"
TITLE="Open Voice OS Installation - Resumen"

export CONTENT TITLE
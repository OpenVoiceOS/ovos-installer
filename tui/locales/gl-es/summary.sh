#!/bin/env bash

CONTENT="
Estás a piques de rematar. Aquí tes un resumo das opcións que escolliches para instalar Open Voice OS:

    - Método:   $METHOD
    - Versión:  $CHANNEL
    - Perfil:   $PROFILE
    - GUI:      $FEATURE_GUI
    - Habilidades:   $FEATURE_SKILLS
    - Axustes:   $TUNING

As decisións tomadas durante a instalación de Open Voice OS foron coidadosamente pensadas para adaptar o noso sistema ás túas necesidades e preferencias.

É correcto este resumo? Se non, podes volver atrás e facer cambios.
"
TITLE="Instalación de Open Voice OS - Recapitulación"

export CONTENT TITLE

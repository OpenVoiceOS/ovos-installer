#!/bin/env bash

CONTENT="Veuillez trouver ci-dessous les information détectées:

    - Système d'exploitation:  ${DISTRO_NAME^} $DISTRO_VERSION
    - Noyau:                   $KERNEL
    - RPi:                     $RASPBERRYPI_MODEL
    - Python:                  $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD:                $CPU_IS_CAPABLE
    - Matériel:                $HARDWARE_DETECTED
    - Environnement virtuel:   $VENV_PATH
    - Serveur de son:          $SOUND_SERVER
    - Serveur graphique:       ${DISPLAY_SERVER^}"
TITLE="Open Voice OS Installation - Détecté"

export CONTENT TITLE
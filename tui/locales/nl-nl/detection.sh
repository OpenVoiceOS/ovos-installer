#!/bin/env bash

CONTENT="
Automatisch herkende systeemeigenschappen:

    - OS:                 ${DISTRO_NAME^} $DISTRO_VERSION
    - Kernel:             $KERNEL
    - RPi:                $RASPBERRYPI_MODEL
    - Python:             $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD:           $CPU_IS_CAPABLE
    - Hardware:           $HARDWARE_DETECTED
    - Venv:               $VENV_PATH
    - Geluid:             $SOUND_SERVER
    - Display:            ${DISPLAY_SERVER^}
"
TITLE="Open Voice OS Installatie - Systeemeigenschappen"

export CONTENT TITLE

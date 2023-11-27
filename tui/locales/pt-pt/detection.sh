#!/bin/env bash

CONTENT="
Propriedades do sistema reconhecidas automaticamente:

    - OS:       ${DISTRO_NAME^} $DISTRO_VERSION
    - Kernel:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Venv:     $VENV_PATH
    - Som:      $SOUND_SERVER
    - Ecrã:     ${DISPLAY_SERVER^}
"
TITLE="Open Voice OS Installation - Propriedades do sistema"

export CONTENT TITLE

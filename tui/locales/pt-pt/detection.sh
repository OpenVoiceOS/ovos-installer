#!/usr/bin/env bash
CONTENT="
Propriedades do sistema reconhecidas automaticamente:

    - OS:       $DISTRO_LABEL
    - Kernel:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardware: $HARDWARE_DETECTED
    - Venv:     $VENV_PATH
    - Som:      $SOUND_SERVER
    - Ecrã:     ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Open Voice OS Instalação - Propriedades do sistema"

export CONTENT TITLE

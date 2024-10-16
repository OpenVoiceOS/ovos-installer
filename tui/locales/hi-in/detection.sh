#!/bin/env bash

CONTENT="
कृपया पता लगाई गई जानकारी को सत्यापित करें:

    - OS:        ${DISTRO_NAME^} $DISTRO_VERSION
    - Kernel:    $KERNEL
    - RPi:       $RASPBERRYPI_MODEL
    - Python:    $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX2/SIMD: $CPU_IS_CAPABLE
    - Hardware:  $HARDWARE_DETECTED
    - Venv:      $VENV_PATH
    - Sound:     $SOUND_SERVER
    - Display:   ${DISPLAY_SERVER^}
"
TITLE="Open Voice OS Installation - सिस्टम जानकारी की पहचान"

export CONTENT TITLE

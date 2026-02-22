#!/usr/bin/env bash
CONTENT="
Automatisch erkannte Systemeigenschaften:

    - OS:       $DISTRO_LABEL
    - Kernel:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardware: $HARDWARE_DETECTED
    - Venv:     $VENV_PATH
    - Sound:    $SOUND_SERVER
    - Display:  ${DISPLAY_SERVER^}
"
TITLE="Eine vorhandene Open Voice OS Installation entdeckt"

export CONTENT TITLE

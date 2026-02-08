#!/bin/env bash

CONTENT="
Mesedez, aurkitu detektatutako informazioa:

    - OS: ${DISTRO_NAME^} $DISTRO_VERSION
    - Kernel: $KERNEL
    - RPi: $RASPBERRYPI_MODEL
    - Python: $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardwarea: $HARDWARE_DETECTED
    - Venv: $VENV_PATH
    - Soinua: $SOUND_SERVER
    - Pantaila: ${DISPLAY_SERVER^}
"
TITLE="Ireki Voice OS instalazioa - Detektatua"

export CONTENT TITLE

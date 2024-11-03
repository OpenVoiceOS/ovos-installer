#!/bin/env bash

CONTENT="
Find de fundne oplysninger:

    - OS: ${DISTRO_NAME^} $DISTRO_VERSION
    - Kernel: $KERNEL
    - RPi: $RASPBERRYPI_MODEL
    - Python: $(ekko "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardware: $HARDWARE_DETECTED
    - Venv: $VENV_PATH
    - Lyd: $SOUND_SERVER
    - Skærm: ${DISPLAY_SERVER^}
"
TITLE="Åbn Voice OS-installation - fundet"

export CONTENT TITLE

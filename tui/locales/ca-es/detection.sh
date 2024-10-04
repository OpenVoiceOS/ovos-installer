#!/bin/env bash

CONTENT="
Trobeu la informació detectada:

    - Sistema operatiu: ${DISTRO_NAME^} $DISTRO_VERSION
    - Nucli: $KERNEL
    - RPi: $RASPBERRYPI_MODEL
    - Python: $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Maquinari: $HARDWARE_DETECTED
    - Venv: $VENV_PATH
    - So: $SOUND_SERVER
    - Visualització: ${DISPLAY_SERVER^}
"
TITLE="Instal·lació del sistema operatiu de veu oberta: detectada"

export CONTENT TITLE

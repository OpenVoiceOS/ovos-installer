#!/usr/bin/env bash
CONTENT="
Información detectada:

    - SO:       $DISTRO_LABEL
    - Kernel:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardware: $HARDWARE_DETECTED
    - Venv:     $VENV_PATH
    - Son:      $SOUND_SERVER
    - Pantalla: ${DISPLAY_DETECTED}
"
TITLE="Instalación de Open Voice OS - Detección"

export CONTENT TITLE

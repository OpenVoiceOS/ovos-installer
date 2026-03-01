#!/usr/bin/env bash
CONTENT="
Automatisch herkende systeemeigenschappen:

    - OS:                 $DISTRO_LABEL
    - Kernel:             $KERNEL
    - RPi:                $RASPBERRYPI_MODEL
    - Python:             $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD:           $CPU_IS_CAPABLE
    - Hardware:           $HARDWARE_DETECTED
    - Venv:               $VENV_PATH
    - Geluid:             $SOUND_SERVER
    - Display:            ${DISPLAY_DETECTED}
"
TITLE="OpenVoice OS Installatie - Systeemeigenschappen"

export CONTENT TITLE

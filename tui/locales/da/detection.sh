#!/usr/bin/env bash
CONTENT="
Find de fundne oplysninger:

    - OS: $DISTRO_LABEL
    - Kernel: $KERNEL
    - RPi: $RASPBERRYPI_MODEL
    - Python: $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardware: $HARDWARE_DETECTED
    - Venv: $VENV_PATH
    - Lyd: $SOUND_SERVER
    - Skærm: ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Open Voice OS-installation - fundet"

HARDWARE_CONFIRMATION_TITLE="Open Voice OS-installation - Hardwarekontrol"
HARDWARE_CONFIRMATION_MARK2_CONTENT="En Raspberry Pi 4 med en TAS5806-lydenhed blev fundet.\n\nDet kan være en Mycroft Mark II, men nogle generiske HAT'er viser det samme signal.\n\nEr denne enhed faktisk en Mycroft Mark II?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="En Raspberry Pi 4 med TAS5806- og attiny1614-enheder blev fundet.\n\nDet kan være en Mycroft DevKit, men nogle generiske HAT'er viser det samme signal.\n\nEr denne enhed faktisk en Mycroft DevKit?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Vælg Nej for at fortsætte med det generiske Raspberry Pi-forløb."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

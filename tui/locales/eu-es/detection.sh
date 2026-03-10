#!/usr/bin/env bash
CONTENT="
Mesedez, aurkitu detektatutako informazioa:

    - OS: $DISTRO_LABEL
    - Kernel: $KERNEL
    - RPi: $RASPBERRYPI_MODEL
    - Python: $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardwarea: $HARDWARE_DETECTED
    - Venv: $VENV_PATH
    - Soinua: $SOUND_SERVER
    - Pantaila: ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Ireki Voice OS instalazioa - Detektatua"

HARDWARE_CONFIRMATION_TITLE="Open Voice OS instalazioa - Hardware egiaztapena"
HARDWARE_CONFIRMATION_MARK2_CONTENT="TAS5806 audio gailu bat duen Raspberry Pi 4 bat detektatu da.\n\nMycroft Mark II bat izan daiteke, baina HAT generiko batzuek seinale bera erakusten dute.\n\nGailu hau benetan Mycroft Mark II bat al da?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="TAS5806 eta attiny1614 gailuak dituen Raspberry Pi 4 bat detektatu da.\n\nMycroft DevKit bat izan daiteke, baina HAT generiko batzuek seinale bera erakusten dute.\n\nGailu hau benetan Mycroft DevKit bat al da?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Aukeratu Ez Raspberry Pi fluxu generikoarekin jarraitzeko."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

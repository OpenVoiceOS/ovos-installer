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
    - Display:            ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="OpenVoice OS Installatie - Systeemeigenschappen"

HARDWARE_CONFIRMATION_TITLE="Open Voice OS Installatie - Hardwarecontrole"
HARDWARE_CONFIRMATION_MARK2_CONTENT="Er is een Raspberry Pi 4 met een TAS5806-audioapparaat gedetecteerd.\n\nDit kan een Mycroft Mark II zijn, maar sommige generieke HAT's tonen hetzelfde signaal.\n\nIs dit apparaat echt een Mycroft Mark II?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="Er is een Raspberry Pi 4 met TAS5806- en attiny1614-apparaten gedetecteerd.\n\nDit kan een Mycroft DevKit zijn, maar sommige generieke HAT's tonen hetzelfde signaal.\n\nIs dit apparaat echt een Mycroft DevKit?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Kies Nee om door te gaan met de generieke Raspberry Pi-stroom."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

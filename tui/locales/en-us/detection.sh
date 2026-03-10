#!/usr/bin/env bash
CONTENT="
Please find the detected information:

    - OS:       $DISTRO_LABEL
    - Kernel:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardware: $HARDWARE_DETECTED
    - Venv:     $VENV_PATH
    - Sound:    $SOUND_SERVER
    - Display:  ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Open Voice OS Installation - Detected"

HARDWARE_CONFIRMATION_TITLE="Open Voice OS Installation - Hardware Check"
HARDWARE_CONFIRMATION_MARK2_CONTENT="A Raspberry Pi 4 with a TAS5806 audio device was detected.\n\nThis can be a Mycroft Mark II, but some generic HATs expose the same signal.\n\nIs this device actually a Mycroft Mark II?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="A Raspberry Pi 4 with TAS5806 and attiny1614 devices was detected.\n\nThis can be a Mycroft DevKit, but some generic HATs expose the same signal.\n\nIs this device actually a Mycroft DevKit?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Choose No to continue with the generic Raspberry Pi flow."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

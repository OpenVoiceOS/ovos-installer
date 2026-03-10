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
    - Display:  ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Eine vorhandene Open Voice OS Installation entdeckt"

HARDWARE_CONFIRMATION_TITLE="Open Voice OS Installation - Hardwareprüfung"
HARDWARE_CONFIRMATION_MARK2_CONTENT="Ein Raspberry Pi 4 mit einem TAS5806-Audiogerät wurde erkannt.\n\nDas kann ein Mycroft Mark II sein, aber einige generische HATs zeigen dasselbe Signal.\n\nIst dieses Gerät tatsächlich ein Mycroft Mark II?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="Ein Raspberry Pi 4 mit TAS5806- und attiny1614-Geräten wurde erkannt.\n\nDas kann ein Mycroft DevKit sein, aber einige generische HATs zeigen dasselbe Signal.\n\nIst dieses Gerät tatsächlich ein Mycroft DevKit?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Wählen Sie Nein, um mit dem generischen Raspberry-Pi-Ablauf fortzufahren."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

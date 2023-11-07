#!/bin/env bash

message="Please find the detected information:

    - OS:       ${DISTRO_NAME^} $DISTRO_VERSION
    - Kernel:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - Venv:     $VENV_PATH
    - Sound:    $SOUND_SERVER
    - Graphic:  ${X_SERVER^}
"

whiptail --msgbox --title "Open Voice OS Installation - Detected" "$message" 25 80

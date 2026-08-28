#!/usr/bin/env bash
CONTENT="
Ttxil-k, ha-tan ddaw-a tilɣa-nni yettwafen.

    - Anagraw:       ${DISTRO_NAME^} $DISTRO_VERSION
    - Iɣes:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Arrum: $HARDWARE_DETECTED
    - Venv:     $VENV_PATH
    - Ameslaw:    $SOUND_SERVER
    - Abeqqeḍ:  ${DISPLAY_SERVER^}
"
TITLE="Asbeddi Open Voice OS - Yettwaf"

export CONTENT TITLE

#!/usr/bin/env bash
CONTENT="
Ttxil-k, ha-tan ddaw-a tilɣa-nni yettwafen.

    - Anagraw n wammud:       $DISTRO_LABEL
    - Iɣes:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Arrum: $HARDWARE_DETECTED
    - Tawennaḍt tuhlist:     $VENV_PATH
    - Aseqdac n umeslaw:    $SOUND_SERVER
    - Aseqdac n ubeqqeḍ:  ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Asbeddi Open Voice OS - Yettwaf"

export CONTENT TITLE

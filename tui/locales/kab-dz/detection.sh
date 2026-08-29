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

HARDWARE_CONFIRMATION_TITLE="Asbeddi n Open Voice OS - Asenqed n warrum"
HARDWARE_CONFIRMATION_MARK2_CONTENT="Yettwaf-d Raspberry Pi 4 akked ubeqqeḍ n umeslaw TAS5806.\n\nAya yezmer ad yili d Mycroft Mark II, maca kra n yiɣewwaren imezganen (HAT) zemren ad d-fkent assaɣ i icban wa.\n\nWarrum-a, d Mycroft Mark II s tidet?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="Yettwaf-d Raspberry Pi 4 akked yibeqqḍen TAS5806 d attiny1614.\n\nAya yezmer ad yili d Mycroft DevKit, maca kra n yiɣewwaren imezganen (HAT) zemren ad d-fkent assaɣ i icban wa.\n\nWarrum-a, d Mycroft DevKit s tidet?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Fren Uhu akken ad tkemmleḍ s webrid amatu n Raspberry Pi."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

#!/usr/bin/env bash
CONTENT="
Veuillez trouver ci-dessous les information détectées:

    - Système d'exploitation:  $DISTRO_LABEL
    - Noyau:                   $KERNEL
    - RPi:                     $RASPBERRYPI_MODEL
    - Python:                  $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD:                $CPU_IS_CAPABLE
    - Matériel:                $HARDWARE_DETECTED
    - Environnement virtuel:   $VENV_PATH
    - Serveur de son:          $SOUND_SERVER
    - Serveur graphique:       ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Open Voice OS Installation - Détecté"

HARDWARE_CONFIRMATION_TITLE="Installation d'Open Voice OS - Vérification du matériel"
HARDWARE_CONFIRMATION_MARK2_CONTENT="Un Raspberry Pi 4 avec un périphérique audio TAS5806 a été détecté.\n\nCela peut être un Mycroft Mark II, mais certains HAT génériques exposent le même signal.\n\nCet appareil est-il réellement un Mycroft Mark II ?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="Un Raspberry Pi 4 avec des périphériques TAS5806 et attiny1614 a été détecté.\n\nCela peut être un Mycroft DevKit, mais certains HAT génériques exposent le même signal.\n\nCet appareil est-il réellement un Mycroft DevKit ?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Choisissez Non pour continuer avec le flux Raspberry Pi générique."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

#!/usr/bin/env bash
CONTENT="
Trobeu la informació detectada:

    - Sistema operatiu: $DISTRO_LABEL
    - Nucli: $KERNEL
    - RPi: $RASPBERRYPI_MODEL
    - Python: $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Maquinari: $HARDWARE_DETECTED
    - Venv: $VENV_PATH
    - So: $SOUND_SERVER
    - Pantalla: ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Instal·lació de l'Open Voice OS - Informació detectada"

HARDWARE_CONFIRMATION_TITLE="Instal·lació de l'Open Voice OS - Verificació del maquinari"
HARDWARE_CONFIRMATION_MARK2_CONTENT="S'ha detectat un Raspberry Pi 4 amb un dispositiu d'àudio TAS5806.\n\nAixò pot ser un Mycroft Mark II, però alguns HAT genèrics exposen el mateix senyal.\n\nAquest dispositiu és realment un Mycroft Mark II?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="S'ha detectat un Raspberry Pi 4 amb dispositius TAS5806 i attiny1614.\n\nAixò pot ser un Mycroft DevKit, però alguns HAT genèrics exposen el mateix senyal.\n\nAquest dispositiu és realment un Mycroft DevKit?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Trieu No per continuar amb el flux genèric de Raspberry Pi."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

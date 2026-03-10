#!/usr/bin/env bash
CONTENT="
Propriedades do sistema reconhecidas automaticamente:

    - OS:       $DISTRO_LABEL
    - Kernel:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardware: $HARDWARE_DETECTED
    - Venv:     $VENV_PATH
    - Som:      $SOUND_SERVER
    - Ecrã:     ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Open Voice OS Instalação - Propriedades do sistema"

HARDWARE_CONFIRMATION_TITLE="Instalação do Open Voice OS - Verificação de hardware"
HARDWARE_CONFIRMATION_MARK2_CONTENT="Foi detetado um Raspberry Pi 4 com um dispositivo de áudio TAS5806.\n\nIsto pode ser um Mycroft Mark II, mas alguns HAT genéricos expõem o mesmo sinal.\n\nEste dispositivo é realmente um Mycroft Mark II?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="Foi detetado um Raspberry Pi 4 com dispositivos TAS5806 e attiny1614.\n\nIsto pode ser um Mycroft DevKit, mas alguns HAT genéricos expõem o mesmo sinal.\n\nEste dispositivo é realmente um Mycroft DevKit?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Escolha Não para continuar com o fluxo genérico de Raspberry Pi."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

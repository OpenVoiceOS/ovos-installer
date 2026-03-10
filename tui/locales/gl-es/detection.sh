#!/usr/bin/env bash
CONTENT="
Información detectada:

    - SO:       $DISTRO_LABEL
    - Kernel:   $KERNEL
    - RPi:      $RASPBERRYPI_MODEL
    - Python:   $(echo "$PYTHON" | awk '{ print $NF }')
    - AVX/SIMD: $CPU_IS_CAPABLE
    - Hardware: $HARDWARE_DETECTED
    - Venv:     $VENV_PATH
    - Son:      $SOUND_SERVER
    - Pantalla: ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Instalación de Open Voice OS - Detección"

HARDWARE_CONFIRMATION_TITLE="Instalación de Open Voice OS - Comprobación de hardware"
HARDWARE_CONFIRMATION_MARK2_CONTENT="Detectouse unha Raspberry Pi 4 cun dispositivo de son TAS5806.\n\nPode ser unha Mycroft Mark II, pero algunhas HAT xenéricas expoñen o mesmo sinal.\n\nEste dispositivo é realmente unha Mycroft Mark II?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="Detectouse unha Raspberry Pi 4 con dispositivos TAS5806 e attiny1614.\n\nPode ser un Mycroft DevKit, pero algunhas HAT xenéricas expoñen o mesmo sinal.\n\nEste dispositivo é realmente un Mycroft DevKit?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Escolle Non para continuar co fluxo xenérico de Raspberry Pi."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

#!/usr/bin/env bash
CONTENT="
Propiedades del sistema reconocidas automáticamente:


- OS: $DISTRO_LABEL
- Kernel: $KERNEL
- RPi: $RASPBERRYPI_MODEL
- Python: $(echo "$PYTHON" | awk '{ print $NF }')
- AVX/SIMD: $CPU_IS_CAPABLE
- Hardware: $HARDWARE_DETECTED
- Venv: $VENV_PATH
- Sound: $SOUND_SERVER
- Display: ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Instalación de Open Voice OS - Propiedades del sistema"

HARDWARE_CONFIRMATION_TITLE="Instalación de Open Voice OS - Comprobación de hardware"
HARDWARE_CONFIRMATION_MARK2_CONTENT="Se ha detectado una Raspberry Pi 4 con un dispositivo de audio TAS5806.\n\nPuede ser una Mycroft Mark II, pero algunas HAT genéricas exponen la misma señal.\n\n¿Este dispositivo es realmente una Mycroft Mark II?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="Se ha detectado una Raspberry Pi 4 con dispositivos TAS5806 y attiny1614.\n\nPuede ser un Mycroft DevKit, pero algunas HAT genéricas exponen la misma señal.\n\n¿Este dispositivo es realmente un Mycroft DevKit?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Elige No para continuar con el flujo genérico de Raspberry Pi."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

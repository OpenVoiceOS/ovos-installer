#!/usr/bin/env bash
CONTENT="
Znajdź wykryte informacje:

- OS: $DISTRO_LABEL
- Kernel: $KERNEL
- RPi: $RASPBERRYPI_MODEL
- Python: $(echo "$PYTHON" | awk '{ print $NF }')
- AVX/SIMD: $CPU_IS_CAPABLE
- Sprzęt: $HARDWARE_DETECTED
- Venv: $VENV_PATH
- Dźwięk: $SOUND_SERVER
- Wyświetlacz: ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Instalacja Open Voice OS - Wykryto"

HARDWARE_CONFIRMATION_TITLE="Instalacja Open Voice OS - Sprawdzenie sprzętu"
HARDWARE_CONFIRMATION_MARK2_CONTENT="Wykryto Raspberry Pi 4 z urządzeniem audio TAS5806.\n\nMoże to być Mycroft Mark II, ale niektóre ogólne HAT-y pokazują ten sam sygnał.\n\nCzy to urządzenie to naprawdę Mycroft Mark II?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="Wykryto Raspberry Pi 4 z urządzeniami TAS5806 i attiny1614.\n\nMoże to być Mycroft DevKit, ale niektóre ogólne HAT-y pokazują ten sam sygnał.\n\nCzy to urządzenie to naprawdę Mycroft DevKit?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Wybierz Nie, aby kontynuować z ogólnym przepływem Raspberry Pi."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

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
- Wyświetlacz: ${DISPLAY_SERVER^}
"
TITLE="Instalacja Open Voice OS - Wykryto"

export CONTENT TITLE

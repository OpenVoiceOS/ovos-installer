#!/usr/bin/env bash
CONTENT="
Queste sono le proprietà del sistema che sono state riconosciute automaticamente:

- Sistema operativo: $DISTRO_LABEL
- Kernel: $KERNEL
- Raspberry Pi: $RASPBERRYPI_MODEL
- Python: $(echo "$PYTHON" | awk '{ print $NF }')
- AVX/SIMD: $CPU_IS_CAPABLE
- Hardware: $HARDWARE_DETECTED
- Venv: $VENV_PATH
- Audio: $SOUND_SERVER
- Schermo: ${DISPLAY_DETECTED}
"
TITLE="Installazione di Open Voice OS - Proprietà del sistema"

export CONTENT TITLE

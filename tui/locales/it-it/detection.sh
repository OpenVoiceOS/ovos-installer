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
- Schermo: ${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}
"
TITLE="Installazione di Open Voice OS - Proprietà del sistema"

HARDWARE_CONFIRMATION_TITLE="Installazione di Open Voice OS - Verifica hardware"
HARDWARE_CONFIRMATION_MARK2_CONTENT="È stato rilevato un Raspberry Pi 4 con un dispositivo audio TAS5806.\n\nPotrebbe essere un Mycroft Mark II, ma alcuni HAT generici espongono lo stesso segnale.\n\nQuesto dispositivo è davvero un Mycroft Mark II?"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="È stato rilevato un Raspberry Pi 4 con dispositivi TAS5806 e attiny1614.\n\nPotrebbe essere un Mycroft DevKit, ma alcuni HAT generici espongono lo stesso segnale.\n\nQuesto dispositivo è davvero un Mycroft DevKit?"
HARDWARE_CONFIRMATION_GENERIC_NOTE="Scegli No per continuare con il flusso generico Raspberry Pi."

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE

#!/usr/bin/env bash

OVERCLOCK_CONTENT="
El overclocking aumenta la frecuencia de la CPU/GPU para obtener el máximo rendimiento, pero puede reducir la estabilidad y aumentar el calor.

Requisitos:
- Refrigeración activa (disipador/ventilador) y buen flujo de aire
- Fuente de alimentación estable adecuada a tu modelo de Pi
- Supervisa las temperaturas y detén si hay throttling o fallos

Riesgos:
- Reinicios aleatorios, fallos de audio, corrupción de datos
- Mayor consumo y vida útil más corta

Open Voice OS no se hace responsable de ningún problema relacionado con el overclocking.

¿Quieres habilitar el overclocking?
"
OVERCLOCK_TITLE="Instalación de Open Voice OS - Overclocking"

OVERCLOCK_CURRENT_VALUES_TITLE="Valores actuales de overclocking:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL

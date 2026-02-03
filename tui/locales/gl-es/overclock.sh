#!/usr/bin/env bash

OVERCLOCK_CONTENT="
O overclocking aumenta a frecuencia da CPU/GPU para un rendemento máximo, pero pode reducir a estabilidade e aumentar a calor.

Requisitos:
- Refrigeración activa (disipador/ventilador) e bo fluxo de aire
- Fonte de alimentación estable axeitada ao teu modelo de Pi
- Monitoriza as temperaturas e detén se hai throttling ou fallos

Riscos:
- Reinicios aleatorios, fallos de audio, corrupción de datos
- Maior consumo e vida útil máis curta

Open Voice OS non é responsable de ningún problema relacionado co overclocking.

Queres activar o overclocking?
"
OVERCLOCK_TITLE="Instalación de Open Voice OS - Overclocking"

OVERCLOCK_CURRENT_VALUES_TITLE="Valores actuais de overclocking:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL

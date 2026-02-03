#!/usr/bin/env bash

OVERCLOCK_CONTENT="
O overclocking aumenta a frequência da CPU/GPU para máximo desempenho, mas pode reduzir a estabilidade e aumentar o calor.

Requisitos:
- Arrefecimento ativo (dissipador/ventoinha) e boa ventilação
- Fonte de alimentação estável adequada ao seu modelo de Pi
- Monitorize as temperaturas e pare se houver limitação térmica ou falhas

Riscos:
- Reinícios aleatórios, falhas de áudio, corrupção de dados
- Maior consumo e redução da vida útil

O Open Voice OS não se responsabiliza por quaisquer problemas relacionados com o overclocking.

Ativar o overclocking?
"
OVERCLOCK_TITLE="Instalação do Open Voice OS - Overclocking"

OVERCLOCK_CURRENT_VALUES_TITLE="Valores atuais de overclocking:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL

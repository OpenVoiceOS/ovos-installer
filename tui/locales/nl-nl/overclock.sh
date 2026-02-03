#!/usr/bin/env bash

OVERCLOCK_CONTENT="
Overclocking verhoogt de CPU/GPU-frequentie voor maximale prestaties, maar kan de stabiliteit verminderen en de warmteontwikkeling verhogen.

Vereisten:
- Actieve koeling (heatsink/ventilator) en goede airflow
- Een stabiele voeding passend bij je Pi-model
- Monitor temperaturen en stop bij throttling of crashes

Risico's:
- Willekeurige herstarts, audioproblemen, gegevenscorruptie
- Hoger stroomverbruik en kortere levensduur

Open Voice OS is niet verantwoordelijk voor problemen die verband houden met overclocking.

Overclocking inschakelen?
"
OVERCLOCK_TITLE="Open Voice OS Installatie - Overclocking"

OVERCLOCK_CURRENT_VALUES_TITLE="Huidige overclock-waarden:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL

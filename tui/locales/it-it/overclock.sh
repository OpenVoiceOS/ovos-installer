#!/usr/bin/env bash

OVERCLOCK_CONTENT="
L’overclocking aumenta la frequenza di CPU/GPU per ottenere le massime prestazioni, ma può ridurre la stabilità e aumentare il calore.

Requisiti:
- Raffreddamento attivo (dissipatore/ventola) e buon flusso d’aria
- Alimentatore stabile adatto al tuo modello di Pi
- Monitora le temperature e interrompi in caso di throttling o crash

Rischi:
- Riavvii casuali, problemi audio, corruzione dei dati
- Maggiore consumo e vita utile ridotta

Open Voice OS non è responsabile di eventuali problemi legati all’overclocking.

Abilitare l’overclocking?
"
OVERCLOCK_TITLE="Installazione di Open Voice OS - Overclocking"

OVERCLOCK_CURRENT_VALUES_TITLE="Valori di overclock attuali:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL

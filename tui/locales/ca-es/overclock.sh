#!/usr/bin/env bash

OVERCLOCK_CONTENT="
L'overclocking augmenta la freqüència de la CPU/GPU per obtenir el màxim rendiment, però pot reduir l'estabilitat i augmentar la calor.

Requisits:
- Refrigeració activa (dissipador/ventilador) i bon flux d'aire
- Font d'alimentació estable adequada al teu model de Pi
- Supervisa les temperatures i atura si hi ha throttling o fallades

Riscos:
- Reinicis aleatoris, fallades d'àudio, corrupció de dades
- Més consum i vida útil més curta

Open Voice OS no és responsable de cap problema relacionat amb l'overclocking.

Voleu habilitar l'overclocking?
"
OVERCLOCK_TITLE="Instal·lació de l'Open VoiceOS - Overclocking"

OVERCLOCK_CURRENT_VALUES_TITLE="Valors actuals d'overclocking:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL

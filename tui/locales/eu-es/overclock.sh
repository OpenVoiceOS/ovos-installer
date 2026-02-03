#!/usr/bin/env bash

OVERCLOCK_CONTENT="
Overclocking-ek CPU/GPU maiztasuna handitzen du errendimendu maximoa lortzeko, baina egonkortasuna murriztu eta beroa handitu dezake.

Baldintzak:
- Hozte aktiboa (dissipagailua/haizagailua) eta aireztapen ona
- Zure Pi modelorako egokia den elikatze-iturri egonkorra
- Tenperaturak kontrolatu eta throttling termikoa edo akatsak badaude gelditu

Arriskuak:
- Berrezarpen ausazkoak, audio arazoak, datuen ustelkeria
- Energia kontsumo handiagoa eta bizitza erabilgarriaren murrizketa

Open Voice OS ez da overclockingarekin lotutako arazoen erantzule.

Overclocking aktibatu?
"
OVERCLOCK_TITLE="Open Voice OS Instalazioa - Overclocking"

OVERCLOCK_CURRENT_VALUES_TITLE="Uneko overclocking balioak:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL

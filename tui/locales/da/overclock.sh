#!/usr/bin/env bash

OVERCLOCK_CONTENT="
Overclocking øger CPU/GPU-frekvensen for maksimal ydeevne, men kan reducere stabiliteten og øge varmeudviklingen.

Krav:
- Aktiv køling (køleplade/blæser) og god luftgennemstrømning
- Stabil strømforsyning passende til din Pi-model
- Overvåg temperaturer og stop ved throttling eller nedbrud

Risici:
- Tilfældige genstarter, lydproblemer, datakorruption
- Højere strømforbrug og kortere levetid

Open Voice OS er ikke ansvarlig for problemer relateret til overclocking.

Aktiver overclocking?
"
OVERCLOCK_TITLE="Open Voice OS-installation - Overclocking"

OVERCLOCK_CURRENT_VALUES_TITLE="Nuværende overclock-værdier:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL

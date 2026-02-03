#!/usr/bin/env bash

OVERCLOCK_CONTENT="
Podkręcanie zwiększa częstotliwość CPU/GPU dla maksymalnej wydajności, ale może obniżyć stabilność i zwiększyć temperaturę.

Wymagania:
- Aktywne chłodzenie (radiator/wentylator) i dobry przepływ powietrza
- Stabilne zasilanie odpowiednie dla modelu Pi
- Monitoruj temperatury i przerwij w razie throttlingu lub awarii

Ryzyka:
- Losowe restarty, problemy z dźwiękiem, uszkodzenie danych
- Większy pobór mocy i krótsza żywotność

Open Voice OS nie ponosi odpowiedzialności za problemy związane z podkręcaniem.

Włączyć podkręcanie?
"
OVERCLOCK_TITLE="Instalacja Open Voice OS - Podkręcanie"

OVERCLOCK_CURRENT_VALUES_TITLE="Bieżące wartości overclockingu:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL

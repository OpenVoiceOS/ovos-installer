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

export OVERCLOCK_CONTENT OVERCLOCK_TITLE

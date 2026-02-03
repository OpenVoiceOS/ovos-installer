#!/usr/bin/env bash

OVERCLOCK_CONTENT="
Übertakten erhöht die CPU/GPU-Frequenz für maximale Leistung, kann aber die Stabilität verringern und die Wärmeentwicklung erhöhen.

Voraussetzungen:
- Aktive Kühlung (Kühlkörper/Lüfter) und guter Luftstrom
- Stabile Stromversorgung passend zu deinem Pi-Modell
- Temperaturen überwachen und bei Throttling oder Abstürzen stoppen

Risiken:
- Zufällige Neustarts, Audioprobleme, Datenkorruption
- Höherer Stromverbrauch und verkürzte Lebensdauer

Open Voice OS ist nicht verantwortlich für Probleme im Zusammenhang mit Übertaktung.

Übertaktung aktivieren?
"
OVERCLOCK_TITLE="Open Voice OS Installation - Übertaktung"

OVERCLOCK_CURRENT_VALUES_TITLE="Aktuelle Overclocking-Werte:"
OVERCLOCK_CURRENT_ARM_FREQ_LABEL="arm_freq"
OVERCLOCK_CURRENT_GPU_FREQ_LABEL="gpu_freq"
OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL="over_voltage"
OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL="initial_turbo"
OVERCLOCK_CURRENT_ARM_BOOST_LABEL="arm_boost"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE OVERCLOCK_CURRENT_VALUES_TITLE OVERCLOCK_CURRENT_ARM_FREQ_LABEL OVERCLOCK_CURRENT_GPU_FREQ_LABEL OVERCLOCK_CURRENT_OVER_VOLTAGE_LABEL OVERCLOCK_CURRENT_INITIAL_TURBO_LABEL OVERCLOCK_CURRENT_ARM_BOOST_LABEL

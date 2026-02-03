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

export OVERCLOCK_CONTENT OVERCLOCK_TITLE

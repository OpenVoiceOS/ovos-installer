#!/usr/bin/env bash
CONTENT="
Für die Installation von Open Voice OS gibt es zwei Umgebungen:

    - Container-Engine wie z.B. Docker
    - Einrichten in einer virtuellen Python-Umgebung

Container bieten Isolierung und einfache Bereitstellung, während eine virtuelle Python-Umgebung mehr Flexibilität und Kontrolle über die Installation bietet.

Wenn die Container-Methode gewählt wird, wird Docker automatisch installiert, wenn es nicht auf dem System vorhanden ist.

Bitte wählen Sie eine Installationsumgebung aus:
"
LOCKED_CONTENT="
Eine vorhandene Installation von Open Voice OS wurde erkannt, daher ist nur die bereits verwendete Methode verfügbar:

    - Erkannte Methode: $INSTANCE_TYPE

Um mit einer anderen Methode zu installieren, deinstallieren Sie zuerst die vorhandene Instanz und starten Sie das Installationsprogramm erneut.

Bitte bestätigen Sie die Installationsmethode:
"
TITLE="Open Voice OS Installation - Installationsumgebung"

export CONTENT LOCKED_CONTENT TITLE

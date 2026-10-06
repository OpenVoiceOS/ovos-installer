#!/usr/bin/env bash
CONTENT="
Open Voice OS wandelt Gesprochenes in Text um (Spracherkennung) und liest seine Antworten vor (Sprachsynthese). Dieser Rechner ist leistungsfähig genug, beides selbst zu erledigen.

- local: Alles läuft auf diesem Rechner. Ihre Stimme bleibt hier, und nichts hängt vom Internet oder von der Auslastung der Server ab. Der Installer lädt die Sprachmodelle für Ihre Sprache herunter, von einigen hundert Megabyte bis zu ein paar Gigabyte, und die Erkennung lastet den Prozessor aus, während Sie sprechen.
- public: Server der Community übernehmen die Arbeit. Sie werden aus gutem Willen betrieben, als Rückfallebene und als Beispiel für selbst gehostete Sprachverarbeitung, nicht als Produktionsdienst: Antworten dauern länger, wenn viele sie gleichzeitig nutzen, und die Server können jederzeit ausfallen. Es muss nichts heruntergeladen werden, aber Ihre Aufnahmen und die Antworten gehen über das Internet und werden auf diesen Servern verarbeitet.

Wenn die lokale Erkennung fehlschlägt oder nichts hört, wird genau diese Aufnahme stattdessen an die öffentlichen Server geschickt.

Bitte wählen Sie, wo die Sprache verarbeitet wird:
"
TITLE="Open Voice OS-Installation - Sprachverarbeitung"
LOCAL_DESCRIPTION="Sprache auf diesem Rechner verarbeiten"
PUBLIC_DESCRIPTION="Öffentliche Server (ich weiß, sie können ausfallen)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

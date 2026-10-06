#!/usr/bin/env bash
CONTENT="
Open Voice OS wandelt Gesprochenes in Text um (Spracherkennung) und liest seine Antworten vor (Sprachsynthese). Dieser Rechner ist leistungsfähig genug, beides selbst zu erledigen.

- local: Alles läuft auf diesem Rechner. Ihre Stimme bleibt hier, und nichts hängt vom Internet oder von der Auslastung der Server ab. Der Installer lädt die Sprachmodelle für Ihre Sprache herunter, von einigen hundert Megabyte bis zu ein paar Gigabyte, und die Erkennung lastet den Prozessor aus, während Sie sprechen.
- public: Die öffentlichen Open Voice OS-Server übernehmen die Arbeit. Es muss nichts heruntergeladen werden, aber jede Anfrage geht über das Internet an Server, die sich die ganze Community teilt. Das kostet Netzwerklaufzeit und wird langsamer, wenn viele sie gleichzeitig nutzen. Ihre Aufnahmen und die Antworten werden auf diesen Servern verarbeitet.

Wenn die lokale Erkennung fehlschlägt oder nichts hört, wird genau diese Aufnahme stattdessen an die öffentlichen Server geschickt.

Bitte wählen Sie, wo die Sprache verarbeitet wird:
"
TITLE="Open Voice OS-Installation - Sprachverarbeitung"
LOCAL_DESCRIPTION="Sprache auf diesem Rechner verarbeiten"
PUBLIC_DESCRIPTION="Öffentliche Open Voice OS-Server nutzen"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

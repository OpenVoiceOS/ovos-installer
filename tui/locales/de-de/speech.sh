#!/usr/bin/env bash
CONTENT="
Open Voice OS wandelt Sprache in Text um (Erkennung) und liest Antworten vor (Synthese).

  - local: dieser Rechner mit öffentlichen Servern als Ersatz. Lädt Sprachmodelle herunter (hunderte Megabyte bis einige Gigabyte). Wenn die lokale Erkennung fehlschlägt oder keinen Text liefert, wird die Aufnahme an öffentliche Server gesendet. Lässt sich die lokale Erkennung oder Synthese nicht einrichten, nutzt dieser Teil öffentliche Server; der Installer weist darauf hin.
  - public: Community-Server verarbeiten Ihre Aufnahmen und gesprochenen Antworten über das Internet. Diese ehrenamtlich betriebenen Ersatzserver sind kein Produktionsdienst: Sie können jederzeit langsamer werden oder ausfallen.

Bitte wählen Sie, wo Sprache verarbeitet wird:
"
TITLE="Open Voice OS-Installation - Sprachverarbeitung"
LOCAL_DESCRIPTION="Dieser Rechner mit öffentlichen Servern als Ersatz"
PUBLIC_DESCRIPTION="Öffentliche Server (ich weiß, sie können ausfallen)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

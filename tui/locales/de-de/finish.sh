#!/usr/bin/env bash
CONTENT="
Die Installation wurde erfolgreich abgeschlossen! 🎉

Ihr Sprachassistent ist jetzt einsatzbereit. Wir freuen uns darauf, dass Sie das breite Spektrum an Funktionen und Möglichkeiten dieses Sprachassistenten erkunden können.

Wenn Sie die Skill-Funktion aktiviert haben, können Sie mit Ihrem Assistenten interagieren, indem Sie sagen:

  - Hey Mycroft, wie spät ist es?
  - Hey Mycroft, wie ist die Temperatur?
  - Hey Mycroft, stelle einen Timer für drei Minuten!
  - Hey Mycroft, wer hat dich gemacht?
  - Hey Mycroft, wer ist Ada Lovelace?
  - Hey Mycroft, was würde Duke Nukem sagen?

Die Einstellungen Ihres Assistenten können in der Konfigurationsdatei ${CONFIG_FILE:-} geändert werden.

Sollten Sie in Zukunft Unterstützung oder Updates benötigen, können Sie sich gerne an uns wenden. Viel Spaß mit Open Voice OS!
"
TITLE="Open Voice OS Installations - Abschluß"

export CONTENT TITLE

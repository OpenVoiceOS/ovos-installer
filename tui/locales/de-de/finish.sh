#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Dieser Satellit muss noch die Freigabe zum Sprechen erhalten, und zwar auf dem Rechner, auf dem der HiveMind-Listener läuft, unter ${HIVEMIND_HOST}:${HIVEMIND_PORT:-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Mit list-clients finden Sie die Node ID, deren Zugangsschlüssel mit ${HIVEMIND_KEY_PREFIX} beginnt - das ist dieser Satellit. Solange die Freigabe nicht erteilt ist, verbindet er sich und authentifiziert sich erfolgreich, aber alles, was er sagt, wird abgewiesen.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

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
$HIVEMIND_SATELLITE_HINT
"
TITLE="Open Voice OS Installations - Abschluß"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT

#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Deze satelliet moet nog toestemming krijgen om te spreken. Dat doe je op de machine waarop de HiveMind listener draait, op ${HIVEMIND_HOST-}:${HIVEMIND_PORT-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Gebruik list-clients om het Node ID te vinden waarvan de toegangssleutel begint ${HIVEMIND_KEY_PREFIX-} - dat is deze satelliet. Zolang die toestemming niet is gegeven, maakt de satelliet wel verbinding en slaagt de authenticatie, maar wordt alles wat hij zegt geweigerd.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
De installatie is met succes voltooid! 🎉

Je stemassistent is nu klaar voor gebruik. We kijken ernaar uit om de vele functies en mogelijkheden van deze stemassistent te ontdekken.

Als je de vaardigheidsfunctie hebt geactiveerd, kun je communiceren met je assistent door te zeggen:

  - Hey Mycroft, hoe laat is het?
  - Hey Mycroft, wat is de temperatuur?
  - Hey Mycroft, zet een timer op drie minuten?
  - Hey Mycroft, wie heeft jou gemaakt?
  - Hey Mycroft, wie is Ada Lovelace?
  - Hey Mycroft, wat zou Duke Nukem zeggen?

De instellingen van je wizard kun je veranderen in het configuratiebestand ${CONFIG_FILE:-}.

Als je in de toekomst ondersteuning of updates nodig hebt, neem dan gerust contact met ons op. Veel plezier met Open Voice OS!
$HIVEMIND_SATELLITE_HINT
"
TITLE="OpenVoice OS Installatie - Voltooid"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT

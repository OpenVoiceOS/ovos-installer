#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Satelite honi oraindik hitz egiteko baimena eman behar zaio, ${HIVEMIND_HOST-}:${HIVEMIND_PORT-5678} helbidean HiveMind entzulea exekutatzen ari den makinan:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Erabili list-clients sarbide-gakoaren hasieran ${HIVEMIND_KEY_PREFIX-} duen Node ID aurkitzeko - hori da satelite hau. Baimena eman arte, satelitea konektatu eta autentifikatu egingo da, baina esaten duen guztia ukatu egingo da.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
Instalazioa behar bezala amaitu da! 🎉

Zure ahots-laguntzailea prest dago. Pozik gaude ahots-laguntzaile honek eskaintzen dituen funtzio eta gaitasun sorta zabala arakatzeko.

Trebetasun-eginbide lehenetsia gaitu baduzu, zure laguntzailearekin elkarreraginean has zaitezke esanez:

  - Hey Mycroft, zer ordu da?
  - Hey Mycroft, zein da tenperatura?
  - Hey Mycroft, nork egin zaitu?
  - Hey Mycroft, nor da Ada Lovelace?
  - Hey Mycroft, zer esango luke Duke Nukemek?

Zure laguntzailearen ezarpenak ${CONFIG_FILE:-} konfigurazio fitxategian alda daitezke.

Etorkizunean laguntza edo eguneratzerik behar baduzu, jar zaitez harremanetan. Gozatu Open Voice OS esperientzia!
$HIVEMIND_SATELLITE_HINT
"
TITLE="Ireki Voice OS instalazioa - Amaitu"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT

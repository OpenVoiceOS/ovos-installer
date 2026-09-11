#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
A este satélite todavía hay que darle permiso para hablar, en la máquina donde se ejecuta el HiveMind Listener, en ${HIVEMIND_HOST-}:${HIVEMIND_PORT:-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Usa list-clients para localizar el Node ID cuya clave de acceso empieza por ${HIVEMIND_KEY_PREFIX-} - ese es este satélite. Mientras no se conceda ese permiso, el satélite se conectará y se autenticará sin problemas, pero todo lo que diga será rechazado.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
¡La instalación se ha completado con éxito! 🎉

Tu asistente de voz ya está listo. Estamos deseando que explores el amplio abanico de funciones y posibilidades de este asistente de voz.

Si has activado la función de habilidades (skills), puedes interactuar con tu asistente diciendo:

  - Hey Mycroft, ¿qué hora es?
  - Hey Mycroft, ¿qué temperatura hace?
  - Hey Mycroft, ¿pones un temporizador en tres minutos?
  - Hey Mycroft, ¿quién te ha hecho?
  - Hey Mycroft, ¿quién es Ada Lovelace?
  - Hey Mycroft, ¿qué diría Duke Nukem?

Los ajustes de tu asistente pueden modificarse en el fichero de configuración ${CONFIG_FILE:-}.

Si necesitas soporte o actualizaciones en el futuro, no dudes en ponerte en contacto con nosotros. ¡Diviértete con Open Voice OS!
$HIVEMIND_SATELLITE_HINT
"
TITLE="Instalación de Open Voice OS - Finalización"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT

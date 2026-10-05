#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Aínda tes que permitir que este satélite fale, na máquina que executa o HiveMind Listener en ${HIVEMIND_HOST-}:${HIVEMIND_PORT:-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Usa list-clients para atopar o Node ID cuxa clave de acceso comeza ${HIVEMIND_KEY_PREFIX-} - ese é este satélite. Mentres non se conceda ese permiso, o satélite conectarase e autenticarase sen problemas, pero rexeitarase todo o que diga.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

# Shown only where the text client exists - finish.sh leaves the command empty for a
# satellite and for a containers server, neither of which has ovos-tui. The command
# itself is not translated.
OVOS_TEXT_CLIENT_NOTE="
Para falar con el desde un terminal, sen micrófono:

  ${OVOS_TEXT_CLIENT_COMMAND-}
"
OVOS_TEXT_CLIENT_HINT="${OVOS_TEXT_CLIENT_COMMAND:+$OVOS_TEXT_CLIENT_NOTE}"

CONTENT="
A instalación completouse con éxito! 🎉

O teu asistente de voz está listo para comezar. Fainos ilusión que explores todas as funcións e capacidades que ofrece.

Se activaches as habilidades predeterminadas, podes interactuar co asistente dicindo:

  - Ei Mycroft, que hora é?
  - Ei Mycroft, que temperatura temos?
  - Ei Mycroft, quen te creou?
  - Ei Mycroft, quen foi Ada Lovelace?
  - Ei Mycroft, que diría Duke Nukem?

Podes cambiar a configuración do asistente no ficheiro de configuración ${CONFIG_FILE:-}.

Se necesitas axuda ou actualizacións no futuro, ponte en contacto con nós. Goza da túa experiencia con Open Voice OS!
$OVOS_TEXT_CLIENT_HINT
$HIVEMIND_SATELLITE_HINT
"
TITLE="Instalación de Open Voice OS - Finalización"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT OVOS_TEXT_CLIENT_NOTE OVOS_TEXT_CLIENT_HINT

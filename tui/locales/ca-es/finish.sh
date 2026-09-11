#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Aquest satèl·lit encara ha de rebre permís per a parlar, a la màquina on s'executa l'escolta de HiveMind a ${HIVEMIND_HOST}:${HIVEMIND_PORT:-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Feu servir list-clients per a trobar el Node ID la clau d'accés del qual comença per ${HIVEMIND_KEY_PREFIX} - aquest és el Node ID d'aquest satèl·lit. Fins que no es concedeixi el permís, el satèl·lit es connectarà i s'autenticarà correctament, però es rebutjarà tot el que digui.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
La instal·lació s'ha completat correctament! 🎉

L'assistent de veu ja està a punt. Ens complau que exploreu l'ampli ventall de funcions i capacitats que ofereix aquest assistent de veu.

Si heu activat la característica d'habilitats predeterminades, podeu començar a interactuar amb el vostre assistent dient:

  - Ei Mycroft, quina hora és?
  - Ei Mycroft, quina temperatura fa?
  - Ei Mycroft, qui et va fer?
  - Ei Mycroft, qui és l'Ada Lovelace?
  - Ei Mycroft, què diria Duke Nukem?

La configuració del vostre assistent es pot canviar al fitxer de configuració ${CONFIG_FILE:-}.

Si us cal ajuda o actualitzacions en el futur, no dubteu a posar-vos en contacte amb nosaltres. Gaudiu de l'experiència amb Open Voice OS!
$HIVEMIND_SATELLITE_HINT
"
TITLE="Instal·lació de l'Open Voice OS - Finalització"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT

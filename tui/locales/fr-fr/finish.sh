#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Ce satellite doit encore être autorisé à parler, sur la machine qui exécute HiveMind Listener à ${HIVEMIND_HOST-}:${HIVEMIND_PORT-5678} :

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Utilisez list-clients pour trouver le Node ID dont la clé d'accès commence par ${HIVEMIND_KEY_PREFIX-} - il s'agit de ce satellite. Tant que cette autorisation n'a pas été accordée, le satellite se connecte et s'authentifie correctement, mais tout ce qu'il dit est refusé.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
L'installation s'est terminée avec succès ! 🎉

Votre assistant vocal est prêt à être utilisé. Nous sommes ravis que vous exploriez le large éventail de fonctionnalités et de capacités que cet assistant vocal a à offrir.

Si vous avez activé la fonctionnalité de compétences par défaut, vous pouvez commencer à interagir avec votre assistant en disant :

  - Hey Mycroft, quelle heure est-il ?
  - Hey Mycroft, quelle est la température ?
  - Hey Mycroft, qui t'a créé ?
  - Hey Mycroft, qui est Ada Lovelace ?
  - Hey Mycroft, qu'est-ce que Duke Nukem dirait ?

Les paramètres de votre assistant peuvent être modifiés dans le fichier de configuration ${CONFIG_FILE:-}.

Si vous avez besoin d'aide ou d'informations, n'hésitez pas à nous contacter. Profitez de votre expérience Open Voice OS !
$HIVEMIND_SATELLITE_HINT
"
TITLE="Open Voice OS Installation - Clap de fin"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT

#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Este satélite ainda tem de ser autorizado a falar, na máquina que executa o HiveMind Listener em ${HIVEMIND_HOST-}:${HIVEMIND_PORT:-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Utilize o list-clients para encontrar o Node ID cuja chave de acesso começa por ${HIVEMIND_KEY_PREFIX-} - esse é este satélite. Enquanto a autorização não for concedida, o satélite liga-se e autentica-se normalmente, mas tudo o que disser é recusado.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
A instalação foi concluída com sucesso! 🎉

O seu assistente de voz está agora pronto a ser utilizado. Esperamos que explore a vasta gama de funções e possibilidades deste assistente de voz.

Se tiver ativado a função Skill, pode interagir com o seu assistente dizendo:

  - Hey Mycroft, que horas são?
  - Hey Mycroft, qual é a temperatura?
  - Hey Mycroft, marca um temporizador para três minutos?
  - Hey Mycroft, quem te criou?
  - Hey Mycroft, quem é Ada Lovelace?
  - Hey Mycroft, o que é que o Duke Nukem diria?

As definições do seu assistente podem ser alteradas no ficheiro de configuração ${CONFIG_FILE:-}.

Se precisar de suporte ou actualizações no futuro, não hesite em contactar-nos. Divirta-se com o Open Voice OS!
$HIVEMIND_SATELLITE_HINT
"
TITLE="Open Voice OS Instalação - Conclusão"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT

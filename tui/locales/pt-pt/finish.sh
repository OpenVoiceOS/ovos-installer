#!/usr/bin/env bash
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
"
TITLE="Open Voice OS Instalação - Conclusão"

export CONTENT TITLE

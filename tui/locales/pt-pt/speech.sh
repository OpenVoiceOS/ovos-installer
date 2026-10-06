#!/usr/bin/env bash
CONTENT="
O Open Voice OS converte o que diz em texto (reconhecimento de voz) e lê as respostas em voz alta (síntese de voz). Esta máquina é suficientemente potente para fazer as duas coisas sozinha.

  - local: tudo corre nesta máquina. A sua voz fica aqui e nada depende da internet nem da ocupação dos servidores. O instalador descarrega os modelos de voz do seu idioma, de algumas centenas de megabytes a alguns gigabytes, e o reconhecimento mantém o processador ocupado enquanto fala.
  - public: o trabalho é feito por servidores da comunidade. São disponibilizados por boa vontade, como reserva e como exemplo de voz auto-alojada, não como um serviço de produção: as respostas demoram mais quando muitas pessoas os usam ao mesmo tempo, e podem ficar indisponíveis a qualquer momento. Não há nada para descarregar, mas as suas gravações e as respostas viajam pela internet e são processadas nesses servidores.

Se o reconhecimento local falhar ou não ouvir nada, essa gravação é enviada para os servidores públicos.

Seleccione onde a voz é processada:
"
TITLE="Open Voice OS Instalação - Voz"
LOCAL_DESCRIPTION="Processar a voz nesta máquina"
PUBLIC_DESCRIPTION="Servidores públicos (sei que podem falhar)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

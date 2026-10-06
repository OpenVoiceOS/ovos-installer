#!/usr/bin/env bash
CONTENT="
O Open Voice OS converte o que diz em texto (reconhecimento de voz) e lê as respostas em voz alta (síntese de voz). Esta máquina é suficientemente potente para fazer as duas coisas sozinha.

  - local: tudo corre nesta máquina. A sua voz fica aqui e nada depende da internet nem da ocupação dos servidores. O instalador descarrega os modelos de voz do seu idioma, de algumas centenas de megabytes a alguns gigabytes, e o reconhecimento mantém o processador ocupado enquanto fala.
  - public: os servidores públicos do Open Voice OS fazem o trabalho. Não há nada para descarregar, mas cada pedido viaja pela internet até servidores partilhados por toda a comunidade, o que acrescenta atraso de rede e fica mais lento quando muitas pessoas os usam ao mesmo tempo. As suas gravações e as respostas são processadas nesses servidores.

Se o reconhecimento local falhar ou não ouvir nada, essa gravação é enviada para os servidores públicos.

Seleccione onde a voz é processada:
"
TITLE="Open Voice OS Instalação - Voz"
LOCAL_DESCRIPTION="Processar a voz nesta máquina"
PUBLIC_DESCRIPTION="Usar os servidores públicos do Open Voice OS"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

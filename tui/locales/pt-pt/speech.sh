#!/usr/bin/env bash
CONTENT="
O Open Voice OS converte a voz em texto (reconhecimento) e lê as respostas em voz alta (síntese).

  - local: esta máquina com servidores públicos de reserva. Descarrega modelos de voz (de centenas de megabytes a alguns gigabytes). Se o reconhecimento local falhar ou não devolver texto, essa gravação é enviada para servidores públicos. Se não for possível configurar o reconhecimento ou a síntese local, essa parte usa servidores públicos; o instalador informa-o.
  - public: os servidores da comunidade processam as suas gravações e as respostas de voz pela internet. Estes servidores de reserva, mantidos por voluntários, não são um serviço de produção: podem ficar lentos ou indisponíveis a qualquer momento.

Seleccione onde a voz é processada:
"
TITLE="Open Voice OS Instalação - Voz"
LOCAL_DESCRIPTION="Esta máquina com servidores públicos de reserva"
PUBLIC_DESCRIPTION="Servidores públicos (sei que podem falhar)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

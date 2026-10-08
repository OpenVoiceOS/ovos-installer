#!/usr/bin/env bash
CONTENT="
L'Open Voice OS converteix la veu en text (reconeixement) i llegeix les respostes en veu alta (síntesi).

  - local: aquest equip amb servidors públics de reserva. Baixa models de veu (de centenars de megabytes a uns quants gigabytes). Si el reconeixement local falla o no retorna text, aquella gravació s'envia als servidors públics. Si no es pot configurar el reconeixement o la síntesi local, aquella part fa servir servidors públics; l'instal·lador ho indica.
  - public: els servidors de la comunitat processen les teves gravacions i les respostes de veu per internet. Aquests servidors de reserva, mantinguts per voluntaris, no són un servei de producció: poden anar lents o deixar de funcionar en qualsevol moment.

Selecciona on es processa la veu:
"
TITLE="Instal·lació de l'Open Voice OS - Veu"
LOCAL_DESCRIPTION="Aquest equip amb servidors públics de reserva"
PUBLIC_DESCRIPTION="Servidors públics (sé que poden caure)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

#!/usr/bin/env bash
CONTENT="
L'Open Voice OS converteix el que dius en text (reconeixement de veu) i llegeix les respostes en veu alta (síntesi de veu). Aquest equip és prou potent per fer totes dues coses ell mateix.

- local: tot s'executa en aquest equip. La teva veu es queda aquí i res no depèn d'internet ni de com d'ocupats estiguin els servidors. L'instal·lador baixa els models de veu del teu idioma, des d'uns quants centenars de megabytes fins a uns quants gigabytes, i el reconeixement manté ocupat el processador mentre parles.
- public: els servidors públics de l'Open Voice OS fan la feina. No cal baixar res, però cada petició viatja per internet fins a servidors que comparteix tota la comunitat, cosa que hi afegeix retard de xarxa i que s'alenteix quan molta gent els fa servir alhora. Les teves gravacions i les respostes es processen en aquests servidors.

Si el reconeixement local falla o no sent res, aquella gravació s'envia als servidors públics.

Selecciona on es processa la veu, si us plau:
"
TITLE="Instal·lació de l'Open Voice OS - Veu"
LOCAL_DESCRIPTION="Processar la veu en aquest equip"
PUBLIC_DESCRIPTION="Servidors públics de l'Open Voice OS"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

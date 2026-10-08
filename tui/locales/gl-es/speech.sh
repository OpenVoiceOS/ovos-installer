#!/usr/bin/env bash
CONTENT="
Open Voice OS converte a voz en texto (recoñecemento) e le as respostas en voz alta (síntese).

  - local: este equipo con servidores públicos de respaldo. Descarga modelos de voz (de centos de megabytes a uns poucos gigabytes). Se o recoñecemento local falla ou non devolve texto, esa gravación envíase a servidores públicos. Se non se pode configurar o recoñecemento ou a síntese local, esa parte usa servidores públicos; o instalador indícao.
  - public: os servidores da comunidade procesan as túas gravacións e as respostas de voz por internet. Estes servidores de respaldo, mantidos por voluntarios, non son un servizo de produción: poden ir máis lentos ou deixar de funcionar en calquera momento.

Selecciona onde se procesa a voz:
"
TITLE="Instalación de Open Voice OS - Voz"
LOCAL_DESCRIPTION="Este equipo con servidores públicos de respaldo"
PUBLIC_DESCRIPTION="Servidores públicos (sei que poden caer)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

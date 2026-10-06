#!/usr/bin/env bash
CONTENT="
Open Voice OS converte o que dis en texto (recoñecemento de voz) e le as súas respostas en voz alta (síntese de voz). Este equipo é abondo potente para facer as dúas cousas el mesmo.

  - local: todo se executa neste equipo. A túa voz queda aquí e nada depende de internet nin de canto de ocupados estean os servidores. O instalador descarga os modelos de voz do teu idioma, desde uns centos de megabytes ata uns poucos gigabytes, e o recoñecemento mantén ocupado o procesador mentres falas.
  - public: o traballo fano servidores da comunidade. Ofrécense de boa vontade, como respaldo e como exemplo de voz autoaloxada, non como un servizo de produción: as respostas tardan máis cando moita xente os usa á vez, e poden deixar de funcionar en calquera momento. Non hai nada que descargar, pero as túas gravacións e as respostas viaxan por internet e procésanse neses servidores.

Se o recoñecemento local falla ou non oe nada, esa gravación envíase aos servidores públicos.

Selecciona onde se procesa a voz:
"
TITLE="Instalación de Open Voice OS - Voz"
LOCAL_DESCRIPTION="Procesar a voz neste equipo"
PUBLIC_DESCRIPTION="Servidores públicos (sei que poden caer)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

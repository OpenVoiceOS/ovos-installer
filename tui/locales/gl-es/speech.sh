#!/usr/bin/env bash
CONTENT="
Open Voice OS converte o que dis en texto (recoñecemento de voz) e le as súas respostas en voz alta (síntese de voz). Este equipo é abondo potente para facer as dúas cousas el mesmo.

  - local: todo se executa neste equipo. A túa voz queda aquí e nada depende de internet nin de canto de ocupados estean os servidores. O instalador descarga os modelos de voz do teu idioma, desde uns centos de megabytes ata uns poucos gigabytes, e o recoñecemento mantén ocupado o procesador mentres falas.
  - public: os servidores públicos de Open Voice OS fan o traballo. Non hai nada que descargar, pero cada petición viaxa por internet ata servidores que comparte toda a comunidade, o que engade atraso de rede e vólvese máis lento cando moita xente os usa á vez. As túas gravacións e as respostas procésanse neses servidores.

Se o recoñecemento local falla ou non oe nada, esa gravación envíase aos servidores públicos.

Selecciona onde se procesa a voz:
"
TITLE="Instalación de Open Voice OS - Voz"
LOCAL_DESCRIPTION="Procesar a voz neste equipo"
PUBLIC_DESCRIPTION="Usar os servidores públicos de Open Voice OS"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

#!/usr/bin/env bash
CONTENT="
Open Voice OS convierte lo que dice en texto (reconocimiento de voz) y lee sus respuestas en voz alta (síntesis de voz). Este equipo es lo bastante potente para hacer ambas cosas por sí mismo.

- local: todo se ejecuta en este equipo. Su voz se queda aquí y nada depende de internet ni de lo ocupados que estén los servidores. El instalador descarga los modelos de voz de su idioma, desde unos cientos de megabytes hasta unos pocos gigabytes, y el reconocimiento mantiene ocupado el procesador mientras habla.
- public: los servidores públicos de Open Voice OS hacen el trabajo. No hay nada que descargar, pero cada petición viaja por internet hasta servidores que comparte toda la comunidad, lo que añade retardo de red y se vuelve más lento cuando muchas personas los usan a la vez. Sus grabaciones y las respuestas se procesan en esos servidores.

Si el reconocimiento local falla o no oye nada, esa grabación se envía a los servidores públicos.

Seleccione dónde se procesa la voz:
"
TITLE="Instalación de Open Voice OS - Voz"
LOCAL_DESCRIPTION="Procesar la voz en este equipo"
PUBLIC_DESCRIPTION="Usar los servidores públicos de Open Voice OS"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

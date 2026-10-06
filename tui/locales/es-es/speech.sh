#!/usr/bin/env bash
CONTENT="
Open Voice OS convierte lo que dice en texto (reconocimiento de voz) y lee sus respuestas en voz alta (síntesis de voz). Este equipo es lo bastante potente para hacer ambas cosas por sí mismo.

- local: todo se ejecuta en este equipo. Su voz se queda aquí y nada depende de internet ni de lo ocupados que estén los servidores. El instalador descarga los modelos de voz de su idioma, desde unos cientos de megabytes hasta unos pocos gigabytes, y el reconocimiento mantiene ocupado el procesador mientras habla.
- public: el trabajo lo hacen servidores de la comunidad. Se ofrecen de buena voluntad, como respaldo y como ejemplo de voz autoalojada, no como un servicio de producción: las respuestas tardan más cuando mucha gente los usa a la vez, y pueden dejar de funcionar en cualquier momento. No hay nada que descargar, pero sus grabaciones y las respuestas viajan por internet y se procesan en esos servidores.

Si el reconocimiento local falla o no oye nada, esa grabación se envía a los servidores públicos.

Seleccione dónde se procesa la voz:
"
TITLE="Instalación de Open Voice OS - Voz"
LOCAL_DESCRIPTION="Procesar la voz en este equipo"
PUBLIC_DESCRIPTION="Servidores públicos (sé que pueden caerse)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

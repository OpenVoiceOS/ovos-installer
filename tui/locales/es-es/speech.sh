#!/usr/bin/env bash
CONTENT="
Open Voice OS convierte la voz en texto (reconocimiento) y lee las respuestas en voz alta (síntesis).

  - local: este equipo con servidores públicos de respaldo. Descarga modelos de voz (de cientos de megabytes a unos pocos gigabytes). Si el reconocimiento local falla o no devuelve texto, esa grabación se envía a servidores públicos. Si no se puede configurar el reconocimiento o la síntesis local, esa parte usa servidores públicos; el instalador lo indica.
  - public: los servidores de la comunidad procesan sus grabaciones y las respuestas de voz por internet. Estos servidores de respaldo, mantenidos por voluntarios, no son un servicio de producción: pueden ralentizarse o dejar de funcionar en cualquier momento.

Seleccione dónde se procesa la voz:
"
TITLE="Instalación de Open Voice OS - Voz"
LOCAL_DESCRIPTION="Este equipo con servidores públicos de respaldo"
PUBLIC_DESCRIPTION="Servidores públicos (sé que pueden caerse)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

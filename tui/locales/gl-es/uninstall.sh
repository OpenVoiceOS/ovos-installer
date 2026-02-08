#!/usr/bin/env bash
CONTENT="
Detectouse unha instalación existente de Open Voice OS.

Como Docker e PipeWire poden terse instalado manualmente ou polo sistema, o instalador non eliminará os seguintes paquetes:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

Queres desinstalar Open Voice OS?
"
TITLE="Instalación de Open Voice OS - Desinstalar"

export CONTENT TITLE

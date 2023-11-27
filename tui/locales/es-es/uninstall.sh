#!/bin/env bash

CONTENT="
Se ha detectado una instancia existente de Open Voice OS.

Como Docker y PipeWire pueden haber sido instalados por el sistema o manualmente, el programa de instalación no eliminará los siguientes paquetes:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

¿Quieres desinstalar Open Voice OS?
"
TITLE="Open Voice OS Installation - Desinstalación"

export CONTENT TITLE

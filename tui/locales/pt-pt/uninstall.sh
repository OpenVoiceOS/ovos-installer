#!/bin/env bash

CONTENT="
Foi detectada uma instância existente do Open Voice OS.

Como o Docker e o PipeWire podem ter sido instalados pelo sistema ou manualmente, o programa de instalação não removerá os seguintes pacotes:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

Pretende desinstalar o Open Voice OS?
"
TITLE="Open Voice OS Instalação - Desinstalação"

export CONTENT TITLE
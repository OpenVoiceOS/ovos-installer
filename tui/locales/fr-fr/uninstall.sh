#!/bin/env bash

CONTENT="
Une instance d'Open Voice OS a été détectée.

Étant donné que Docker et PipeWire peuvent avoir été installés par le système ou manuellement, l'ínstallateur ne supprimera pas les packages suivants:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

Voulez-vous désinstaller Open Voice OS?
"
TITLE="Open Voice OS Installation - Désinstallation"

export CONTENT TITLE
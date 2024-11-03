#!/bin/env bash

CONTENT="
En eksisterende forekomst af Open Voice OS er blevet fundet.

Da Docker og PipeWire muligvis er blevet installeret af systemet eller manuelt, vil installationsprogrammet ikke fjerne følgende pakker:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - rørledning
  - pipewire-alsa

Vil du afinstallere Open Voice OS?
"
TITLE="Open Voice OS Installation - Afinstaller"

export CONTENT TITLE

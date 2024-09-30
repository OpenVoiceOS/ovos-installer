#!/bin/env bash

CONTENT="
Es wurde eine vorhandene Instanz von Open Voice OS erkannt.

Da Docker und PipeWire möglicherweise vom System oder manuell installiert wurden, wird das Installationsprogramm die folgenden Pakete nicht entfernen:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

Möchten Sie Open Voice OS deinstallieren?
"
TITLE="Open Voice OS Installation - Deinstallation"

export CONTENT TITLE
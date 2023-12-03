#!/bin/env bash

CONTENT="
È stata rilevata un'istanza esistente di Open Voice OS.

Poiché Docker e PipeWire possono essere stati installati dal sistema o manualmente, il programma di installazione non rimuoverà i seguenti pacchetti:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

Volete disinstallare Open Voice OS?
"
TITLE="Open Voice OS Installation - Disinstallazione"

export CONTENT TITLE

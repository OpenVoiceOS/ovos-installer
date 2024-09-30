#!/bin/env bash

CONTENT="
Er is een bestaande installatie van Open Voice OS gedetecteerd.

Aangezien Docker en PipeWire door het systeem (of handmatig) kunnen zijn geïnstalleerd, verwijdert het installatieprogramma de volgende pakketten niet:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

Wil je Open Voice OS verwijderen?
"
TITLE="Open Voice OS Installatie - Deïnstallatie"

export CONTENT TITLE
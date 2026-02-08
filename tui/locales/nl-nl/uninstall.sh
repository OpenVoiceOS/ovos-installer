#!/usr/bin/env bash
CONTENT="
Er is een bestaande installatie van OpenVoice OS gedetecteerd.

Aangezien Docker en PipeWire door het systeem (of handmatig) kunnen zijn geïnstalleerd, verwijdert het installatieprogramma de volgende pakketten niet:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

Wil je OpenVoice OS verwijderen?
"
TITLE="OpenVoice OS Installatie - Deïnstallatie"

export CONTENT TITLE

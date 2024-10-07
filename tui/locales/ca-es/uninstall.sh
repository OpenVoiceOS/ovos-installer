#!/bin/env bash

CONTENT="
S'ha detectat una instància existent d'Open Voice OS.

Atès que Docker i PipeWire potser s'han instal·lat des del sistema o manualment, l'instal·lador no eliminarà els paquets següents:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

Voleu desinstal·lar l'Open Voice OS?
"
TITLE="Instal·lació de l'Open VoiceOS - Desinstal·lació"

export CONTENT TITLE

#!/bin/env bash

CONTENT="
S'ha detectat una instància existent d'Open Voice OS.

Com que Docker i PipeWire poden haver estat instal·lats pel sistema o manualment, l'instal·lador no eliminarà els paquets següents:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - cable de canonada
  - pipewire-alsa

Voleu desinstal·lar Open Voice OS?
"
TITLE="Obriu la instal·lació de Voice OS - Desinstal·la"

export CONTENT TITLE

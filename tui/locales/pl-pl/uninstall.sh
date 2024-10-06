#!/bin/env bash

CONTENT="
Wykryto istniejącą instancję Open Voice OS.

Ponieważ Docker i PipeWire mogły zostać zainstalowane przez system lub ręcznie, instalator nie usunie następujących pakietów:

- docker-ce
- docker-compose-plugin
- docker-ce-rootless-extras
- docker-buildx-plugin
- pipewire
- pipewire-alsa

Czy chcesz odinstalować Open Voice OS?
"
TITLE="Instalacja Open Voice OS - Odinstaluj"

export CONTENT TITLE

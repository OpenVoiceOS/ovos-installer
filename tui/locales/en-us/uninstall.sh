#!/bin/env bash

CONTENT="
An existing instance of Open Voice OS has been detected.

Because Docker and PipeWire might have been installed by the system or manually, the installer will not remove the following packages:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

Do you want to uninstall Open Voice OS?
"
TITLE="Open Voice OS Installation - Uninstall"

export CONTENT TITLE

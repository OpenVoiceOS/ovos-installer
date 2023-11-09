#!/bin/env bash

export CONFIRM_UNINSTALL="true"

message="An existing instance of Open Voice OS has been detected.

Because Docker and PipeWire might have been installed by the system or manually, the installer will not remove the following packages:

  - docker-ce
  - docker-compose-plugin
  - docker-ce-rootless-extras
  - docker-buildx-plugin
  - pipewire
  - pipewire-alsa

Do you want to uninstall Open Voice OS?
"

whiptail --yesno --defaultno --title "Open Voice OS Installation - Uninstall" "$message" 25 80

exit_status=$?
if [ "$exit_status" = 1 ]; then
  export CONFIRM_UNINSTALL="false"
fi

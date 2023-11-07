#!/bin/bash

message="
By connecting to the Hivemind listener, HiveMind satellites gain access to a network of shared knowledge and capabilities, facilitating a unified and efficient voice assistant and automation experience.

Please enter the HiveMind listener password related to the satellite:"

SATELLITE_PASSWORD=$(whiptail --passwordbox --title "Open Voice OS Installation - Satellite 4/4" "$message" 25 80 3>&1 1>&2 2>&3)
export SATELLITE_PASSWORD

exit_status=$?
if [ "$exit_status" = 1 ]; then
  exit 1
fi

#!/bin/bash

message="
By connecting to the Hivemind listener, HiveMind satellites gain access to a network of shared knowledge and capabilities, facilitating a unified and efficient voice assistant and automation experience.

Please enter the HiveMind listener key related to the satellite:"

SATELLITE_KEY=$(whiptail --passwordbox --title "Open Voice OS Installation - Satellite 3/4" "$message" 25 80 3>&1 1>&2 2>&3)
export SATELLITE_KEY

exit_status=$?
if [ "$exit_status" = 1 ]; then
  exit 1
fi

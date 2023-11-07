#!/bin/env bash

message="
In today's quest for the perfect digital companion, we find ourselves at a crossroads with three intriguing choices:

  - Open Voice OS: The Open Voice OS classic experience
  - HiveMind Satellite: Run only the audio components on a device
  - HiveMind Listener: Hub for HiveMind Satellite to connect to

Each of these profiles offers unique features and capabilities that could greatly enhance your digital experience.

The question is, which one aligns best with your needs and preferences?

Please select a profile:
"

active_profile="ovos"
available_profiles=( ovos satellite listener )

whiptail_args=(
    --title "Open Voice OS Installation - Profiles"
    --radiolist "$message"
    --cancel-button "Exit"
    25 80 "${#available_profiles[@]}"
)

for method in "${available_profiles[@]}"; do
  whiptail_args+=( "$method" "" )
  if [[ $method = "$active_profile" ]]; then
    whiptail_args+=( "on" )
  else
    whiptail_args+=( "off" )
  fi
done

PROFILE=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
export PROFILE

if [ "$PROFILE" = "" ]; then
  exit 1
fi

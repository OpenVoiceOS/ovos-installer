#!/bin/env bash

message="
Open Voice OS has two main release channels:

  - stable (recommended)
  - development

The stable release of Open Voice OS is a well-tested and reliable version suitable for everyday use.

The development release of Open Voice OS is intended for developers and enthusiasts who want to experiment with cutting-edge features and contribute to the platform's development.

Please select a channel:
"

active_channel="development"
available_channels=( stable development )

whiptail_args=(
    --title "Open Voice OS Installation - Channels"
    --radiolist "$message"
    --cancel-button "Exit"
    25 80 "${#available_channels[@]}"
)

for channel in "${available_channels[@]}"; do
  whiptail_args+=( "$channel" "" )
  if [[ $channel = "$active_channel" ]]; then
    whiptail_args+=( "on" )
  else
    whiptail_args+=( "off" )
  fi
done

CHANNEL=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
export CHANNEL

if [ "$CHANNEL" = "" ]; then
  exit 1
fi
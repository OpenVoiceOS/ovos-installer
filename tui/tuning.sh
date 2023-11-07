#!/bin/env bash

message="Using Open Voice OS Tuning for Raspberry Pi involves optimizing the operating system to run efficiently on the Raspberry Pi hardware.

This tuning process aims to enhance performance, reduce resource usage, and ensure a smoother user experience, making it an excellent choice for resource-constrained devices like the Raspberry Pi.

Please note that tuning may require technical expertise and could impact stability. Exercise caution and back up data before making any modifications.

Enable tuning for Raspberry Pi:
"

active_option="no"
available_options=( no yes )

whiptail_args=(
    --title "Open Voice OS Installation - Tuning"
    --radiolist "$message"
    --cancel-button "Exit"
    25 80 "${#available_options[@]}"
)

for option in "${available_options[@]}"; do
  whiptail_args+=( "$option" "" )
  if [[ $option = "$active_option" ]]; then
    whiptail_args+=( "on" )
  else
    whiptail_args+=( "off" )
  fi
done

TUNING=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
export TUNING

if [ "$TUNING" = "" ]; then
  exit 1
fi

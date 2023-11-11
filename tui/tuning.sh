#!/bin/env bash

source "tui/locales/$LOCALE/tuning.sh"

active_option="no"
available_options=( no yes )

whiptail_args=(
    --title "$TITLE"
    --radiolist "$CONTENT"
    --cancel-button "$CANCEL_BUTTON"
    --ok-button "$OK_BUTTON"
    --yes-button "$OK_BUTTON"
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

#!/bin/env bash

message="To install Open Voice OS, you have two primary methods:

    - Containers engine such as Docker or Podman
    - Setting it up in a Python virtual environment

Containers provide isolation and easy deployment, while a Python virtual environment offers more flexibility and control over the installation.

Please select an installation method:
"

active_method="containers"
available_methods=( containers virtualenv )

whiptail_args=(
    --title "Open Voice OS Installation - Methods"
    --radiolist "$message"
    --cancel-button "Exit"
    25 80 "${#available_methods[@]}"
)

for method in "${available_methods[@]}"; do
  whiptail_args+=( "$method" "" )
  if [[ $method = "$active_method" ]]; then
    whiptail_args+=( "on" )
  else
    whiptail_args+=( "off" )
  fi
done

METHOD=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
export METHOD

if [ "$METHOD" = "" ]; then
  exit 1
fi
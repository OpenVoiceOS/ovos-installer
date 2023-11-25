#!/bin/env bash

# shellcheck source=locales/en-us/methods.sh
source "tui/locales/$LOCALE/methods.sh"

declare -a available_methods
active_method="containers"
available_methods=(containers virtualenv)

# Limit available method to match the existing instance
# If containers instance has been deployed then only containers
# method will be available.
if [ "$EXISTING_INSTANCE" == "true" ]; then
  active_method="$INSTANCE_TYPE"
  available_methods=("$INSTANCE_TYPE")
fi

whiptail_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$CANCEL_BUTTON"
  --ok-button "$OK_BUTTON"
  --yes-button "$OK_BUTTON"
  25 80 "${#available_methods[@]}"
)

for method in "${available_methods[@]}"; do
  whiptail_args+=("$method" "")
  if [[ $method = "$active_method" ]]; then
    whiptail_args+=("on")
  else
    whiptail_args+=("off")
  fi
done

METHOD=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
export METHOD

if [ -z "$METHOD" ]; then
  exit 0
fi

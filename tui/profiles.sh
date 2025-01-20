#!/bin/env bash

# shellcheck source=locales/en-us/profiles.sh
source "tui/locales/$LOCALE/profiles.sh"

# Default active and available profiles
active_profile="ovos"
available_profiles=(ovos satellite listener server)

# Handle existing installation
if [ -f "$INSTALLER_STATE_FILE" ]; then
  if jq -e 'has("profile")' "$INSTALLER_STATE_FILE" &>>"$LOG_FILE"; then
    current_profile=$(jq -re '.profile' "$INSTALLER_STATE_FILE")
    active_profile="$current_profile"
    available_profiles=("$current_profile")
  fi
fi

whiptail_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  --yes-button "$OK_BUTTON"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "${#available_profiles[@]}"
)

for method in "${available_profiles[@]}"; do
  whiptail_args+=("$method" "")
  if [[ $method = "$active_profile" ]]; then
    whiptail_args+=("on")
  else
    whiptail_args+=("off")
  fi
done

PROFILE=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
export PROFILE

if [ -z "$PROFILE" ]; then
  source tui/channels.sh
  source tui/profiles.sh
fi

jq -en --arg profile "$PROFILE" '.profile += $profile' > "$TEMP_PROFILE_FILE"


#!/bin/env bash

# shellcheck source=tui/locales/en-us/profiles.sh
source "tui/locales/$LOCALE/profiles.sh"

# Default active and available profiles
active_profile="ovos"
available_profiles=(ovos satellite listener server)

# If a previous selection exists, use it as the default. Only lock the choice
# to that value when upgrading an existing installation.
if [ -f "$INSTALLER_STATE_FILE" ]; then
  current_profile="$(jq -r '.profile // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE")"
  case "$current_profile" in
    ovos|satellite|listener|server)
      active_profile="$current_profile"
      if [ "${EXISTING_INSTANCE:-false}" == "true" ]; then
        available_profiles=("$current_profile")
      fi
      ;;
  esac
fi

list_height="${#available_profiles[@]}"
if [ "$list_height" -lt 1 ]; then
  available_profiles=(ovos satellite listener server)
  list_height="${#available_profiles[@]}"
fi
if [ "$list_height" -lt 4 ]; then
  list_height=4
fi

whiptail_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "$list_height"
)

for method in "${available_profiles[@]}"; do
  whiptail_args+=("$method" "")
  if [[ $method = "$active_profile" ]]; then
    whiptail_args+=("ON")
  else
    whiptail_args+=("OFF")
  fi
done

PROFILE=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
export PROFILE

if [ -z "$PROFILE" ]; then
  source tui/channels.sh
  source tui/profiles.sh
  return
fi

# Persist selection (used for defaults when navigating back or re-running).
state_tmp="$(mktemp)"
if [ -f "$INSTALLER_STATE_FILE" ] && \
  jq --arg profile "$PROFILE" \
    'if type=="object" then . else {} end | .profile = $profile' \
    "$INSTALLER_STATE_FILE" >"$state_tmp" 2>>"$LOG_FILE"; then
  mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
else
  jq -n --arg profile "$PROFILE" '{profile: $profile}' >"$state_tmp" 2>>"$LOG_FILE" && \
    mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
fi

# Keep state writable by the target user when running under sudo/root.
if [ -n "${RUN_AS:-}" ] && [ -f "$INSTALLER_STATE_FILE" ]; then
  chown "$RUN_AS":"$(id -ng "$RUN_AS" 2>>"$LOG_FILE")" "$INSTALLER_STATE_FILE" &>>"$LOG_FILE" || true
fi

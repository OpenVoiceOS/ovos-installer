#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh
# shellcheck source=tui/locales/en-us/speech.sh
source "tui/locales/$LOCALE/speech.sh"

# The flow only shows this screen when local_speech_available, so both choices
# can actually be installed. Local is what the hardware was checked for.
active_engine="local"
if [ -f "$INSTALLER_STATE_FILE" ]; then
  saved_engine="$(jq -r '.speech_engine // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE")"
  case "$saved_engine" in
    local|public)
      active_engine="$saved_engine"
      ;;
  esac
fi

whiptail_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" 4
)

for engine in local public; do
  if [ "$engine" == "local" ]; then
    whiptail_args+=("$engine" "$LOCAL_DESCRIPTION")
  else
    whiptail_args+=("$engine" "$PUBLIC_DESCRIPTION")
  fi
  if [ "$engine" == "$active_engine" ]; then
    whiptail_args+=("ON")
  else
    whiptail_args+=("OFF")
  fi
done

if ! tui_nav_capture SPEECH_ENGINE "${whiptail_args[@]}"; then
  SPEECH_ENGINE="$active_engine"
  export SPEECH_ENGINE
  return 0
fi
export SPEECH_ENGINE

# Persist selection (used for defaults when navigating back or re-running).
state_tmp="$(mktemp)"
if [ -f "$INSTALLER_STATE_FILE" ] && \
  jq --arg speech_engine "$SPEECH_ENGINE" \
    'if type=="object" then . else {} end | .speech_engine = $speech_engine' \
    "$INSTALLER_STATE_FILE" >"$state_tmp" 2>>"$LOG_FILE"; then
  mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
else
  jq -n --arg speech_engine "$SPEECH_ENGINE" '{speech_engine: $speech_engine}' >"$state_tmp" 2>>"$LOG_FILE" && \
    mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
fi

# Keep state writable by the target user when running under sudo/root.
if [ -n "${RUN_AS:-}" ] && [ -f "$INSTALLER_STATE_FILE" ]; then
  chown "$RUN_AS":"$(id -ng "$RUN_AS" 2>>"$LOG_FILE")" "$INSTALLER_STATE_FILE" &>>"$LOG_FILE" || true
fi

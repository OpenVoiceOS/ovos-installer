#!/usr/bin/env bash
# shellcheck source=tui/locales/en-us/homeassistant.sh
_homeassistant_locale_file="tui/locales/$LOCALE/homeassistant.sh"
if [ -f "$_homeassistant_locale_file" ]; then
  source "$_homeassistant_locale_file"
else
  # Fallback for locales that don't have this file yet.
  source "tui/locales/en-us/homeassistant.sh"
fi

# Some locales may not define every message yet; keep strict mode friendly.
: "${CONTENT_INVALID_URL:=Invalid URL.}"
: "${CONTENT_INVALID_PORT:=$CONTENT_INVALID_URL}"

# Safe defaults for strict mode
export FEATURE_HOMEASSISTANT="false"
export HOMEASSISTANT_URL="${HOMEASSISTANT_URL:-}"
HOMEASSISTANT_API_KEY="${HOMEASSISTANT_API_KEY:-}"

# If we already have both values in the current session, don't prompt again.
if [ -n "${HOMEASSISTANT_URL}" ] && [ -n "${HOMEASSISTANT_API_KEY}" ]; then
  export FEATURE_HOMEASSISTANT="true"
  return
fi

ha_url_default=""
if [ -f "$INSTALLER_STATE_FILE" ]; then
  ha_url_default="$(jq -r '.homeassistant.url // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE")"
fi
if [ -z "$ha_url_default" ]; then
  ha_url_default="http://homeassistant.local:8123"
fi

whiptail --yesno --yes-button "$YES_BUTTON" --no-button "$NO_BUTTON" \
  --title "$TITLE_HAVE_DETAILS" "$CONTENT_HAVE_DETAILS" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

exit_status=$?
if [ "$exit_status" -ne 0 ]; then
  # No (1): skip. ESC (255): go back to the feature selection.
  export FEATURE_HOMEASSISTANT="false"
  export HOMEASSISTANT_URL=""
  HOMEASSISTANT_API_KEY=""
  if [ "$exit_status" -eq 255 ]; then
    export HOMEASSISTANT_BACK="true"
  fi
  return
fi

HOMEASSISTANT_URL="$ha_url_default"
while :; do
  HOMEASSISTANT_URL=$(whiptail --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$TITLE_URL" "$CONTENT_URL" 25 80 "$HOMEASSISTANT_URL" 3>&1 1>&2 2>&3)

  exit_status=$?
  if [ "$exit_status" -ne 0 ]; then
    export HOMEASSISTANT_BACK="true"
    export FEATURE_HOMEASSISTANT="false"
    export HOMEASSISTANT_URL=""
    HOMEASSISTANT_API_KEY=""
    return
  fi

  # Remove whitespace and trailing slash; allow entering host:port without scheme.
  HOMEASSISTANT_URL="${HOMEASSISTANT_URL//[[:space:]]/}"
  HOMEASSISTANT_URL="${HOMEASSISTANT_URL%/}"
  if [ -z "$HOMEASSISTANT_URL" ]; then
    whiptail --msgbox --title "$TITLE_INVALID" "$CONTENT_MISSING_INFO" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  if [[ "$HOMEASSISTANT_URL" != http://* && "$HOMEASSISTANT_URL" != https://* ]]; then
    if [[ "$HOMEASSISTANT_URL" == *"://"* ]]; then
      whiptail --msgbox --title "$TITLE_INVALID" "$CONTENT_INVALID_URL" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
      continue
    fi
    HOMEASSISTANT_URL="http://${HOMEASSISTANT_URL}"
  fi

  # Home Assistant defaults to port 8123. If the user doesn't specify a port,
  # add it so "homeassistant.local" works out of the box.
  proto="${HOMEASSISTANT_URL%%://*}"
  rest="${HOMEASSISTANT_URL#*://}"
  authority="${rest%%/*}"
  if [[ "$rest" == */* ]]; then
    path="/${rest#*/}"
  else
    path=""
  fi

  if [ -z "$authority" ]; then
    whiptail --msgbox --title "$TITLE_INVALID" "$CONTENT_MISSING_INFO" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  if [[ "$authority" == \[* ]]; then
    # Bracketed IPv6 host, with optional numeric port.
    if [[ "$authority" =~ ^\\[[^\\]]+\\]$ ]]; then
      authority="${authority}:8123"
    elif [[ "$authority" =~ ^\\[[^\\]]+\\]:[0-9]+$ ]]; then
      :
    else
      whiptail --msgbox --title "$TITLE_INVALID" "$CONTENT_INVALID_PORT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
      continue
    fi
  else
    if [[ "$authority" =~ : ]]; then
      # host:port with numeric port only
      if [[ "$authority" =~ ^[^:/]+:[0-9]+$ ]]; then
        :
      else
        whiptail --msgbox --title "$TITLE_INVALID" "$CONTENT_INVALID_PORT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
        continue
      fi
    else
      authority="${authority}:8123"
    fi
  fi

  HOMEASSISTANT_URL="${proto}://${authority}${path}"
  break
done

while :; do
  # If `set -x` is enabled, avoid echoing secrets to the terminal/logs.
  _ha_xtrace_was_on="false"
  case "$-" in
    *x*) _ha_xtrace_was_on="true" ;;
  esac
  if [ "$_ha_xtrace_was_on" == "true" ]; then
    set +x
  fi

  HOMEASSISTANT_API_KEY=$(whiptail --passwordbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$TITLE_TOKEN" "$CONTENT_TOKEN" 25 80 3>&1 1>&2 2>&3)

  exit_status=$?
  if [ "$_ha_xtrace_was_on" == "true" ]; then
    set -x
  fi
  if [ "$exit_status" -ne 0 ]; then
    export HOMEASSISTANT_BACK="true"
    export FEATURE_HOMEASSISTANT="false"
    export HOMEASSISTANT_URL=""
    HOMEASSISTANT_API_KEY=""
    return
  fi

  if [ -z "$HOMEASSISTANT_API_KEY" ]; then
    whiptail --msgbox --title "$TITLE_INVALID" "$CONTENT_MISSING_INFO" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  break
done

export FEATURE_HOMEASSISTANT="true"

# Persist URL (non-secret) for defaults when navigating back or re-running.
state_tmp="$(mktemp)"
if [ -f "$INSTALLER_STATE_FILE" ]; then
  if jq --arg url "$HOMEASSISTANT_URL" \
    'if type=="object" then . else {} end | .homeassistant = ((.homeassistant // {}) + {url: $url})' \
    "$INSTALLER_STATE_FILE" >"$state_tmp" 2>>"$LOG_FILE"; then
    mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
  else
    # Avoid clobbering existing state if the JSON is corrupt.
    printf '%s\n' "[warn] homeassistant: invalid state file; skipping persistence: $INSTALLER_STATE_FILE" >>"$LOG_FILE" 2>/dev/null || true
    rm -f "$state_tmp"
  fi
else
  if jq -n --arg url "$HOMEASSISTANT_URL" '{homeassistant: {url: $url}}' >"$state_tmp" 2>>"$LOG_FILE"; then
    mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
  else
    rm -f "$state_tmp"
  fi
fi

# Keep state writable by the target user when running under sudo/root.
if [ -n "${RUN_AS:-}" ] && [ -f "$INSTALLER_STATE_FILE" ]; then
  chown "$RUN_AS":"$(id -ng "$RUN_AS" 2>>"$LOG_FILE")" "$INSTALLER_STATE_FILE" &>>"$LOG_FILE" || true
fi

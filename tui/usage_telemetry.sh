#!/usr/bin/env bash
export SHARE_USAGE_TELEMETRY="true"

# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh

_usage_telemetry_locale_file="tui/locales/$LOCALE/usage_telemetry.sh"
if [ -f "$_usage_telemetry_locale_file" ]; then
  # shellcheck source=tui/locales/en-us/usage_telemetry.sh
  source "$_usage_telemetry_locale_file"
else
  # Fallback for locales that don't have this file yet.
  # shellcheck source=tui/locales/en-us/usage_telemetry.sh
  source "tui/locales/en-us/usage_telemetry.sh"
fi

if ! tui_whiptail_dialog --yesno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"; then
  export SHARE_USAGE_TELEMETRY="false"
fi

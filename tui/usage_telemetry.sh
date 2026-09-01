#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh

_usage_telemetry_locale_file="tui/locales/$LOCALE/usage_telemetry.sh"
if [ -f "$_usage_telemetry_locale_file" ]; then
  # shellcheck source=tui/locales/en-us/usage_telemetry.sh
  source "$_usage_telemetry_locale_file"
else
  # Fallback for locales that don't have this file yet.
  # shellcheck source=tui/locales/en-us/usage_telemetry.sh
  source "tui/locales/en-us/usage_telemetry.sh"
fi

# See tui/telemetry.sh: a radiolist so the cancel button can mean "Back".
usage_telemetry_options=(yes no)
usage_telemetry_active_option="yes"
case "${SHARE_USAGE_TELEMETRY_CHOICE:-}" in
yes | no)
  usage_telemetry_active_option="$SHARE_USAGE_TELEMETRY_CHOICE"
  ;;
esac

usage_telemetry_list_height="${#usage_telemetry_options[@]}"
if [ "$usage_telemetry_list_height" -lt 4 ]; then
  usage_telemetry_list_height=4
fi

usage_telemetry_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "$usage_telemetry_list_height"
)

for usage_telemetry_option in "${usage_telemetry_options[@]}"; do
  usage_telemetry_args+=("$usage_telemetry_option" "")
  if [ "$usage_telemetry_option" == "$usage_telemetry_active_option" ]; then
    usage_telemetry_args+=("ON")
  else
    usage_telemetry_args+=("OFF")
  fi
done

usage_telemetry_choice=""
if ! tui_nav_capture usage_telemetry_choice "${usage_telemetry_args[@]}"; then
  return 0
fi

case "$usage_telemetry_choice" in
yes | no)
  SHARE_USAGE_TELEMETRY_CHOICE="$usage_telemetry_choice"
  ;;
*)
  SHARE_USAGE_TELEMETRY_CHOICE="$usage_telemetry_active_option"
  ;;
esac
export SHARE_USAGE_TELEMETRY_CHOICE

if [ "$SHARE_USAGE_TELEMETRY_CHOICE" == "yes" ]; then
  export SHARE_USAGE_TELEMETRY="true"
else
  export SHARE_USAGE_TELEMETRY="false"
fi

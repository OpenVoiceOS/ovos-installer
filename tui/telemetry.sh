#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh

# shellcheck source=tui/locales/en-us/telemetry.sh
source "tui/locales/$LOCALE/telemetry.sh"

# A radiolist rather than a yes/no box: the cancel button is then free to mean
# "Back", so the last screens before the install are not a one-way door.
# SHARE_TELEMETRY_CHOICE remembers the answer across a back-and-forth, while
# SHARE_TELEMETRY itself defaults to "false" for non-interactive runs and so
# cannot be used to preselect anything here.
telemetry_options=(yes no)
telemetry_active_option="yes"
case "${SHARE_TELEMETRY_CHOICE:-}" in
yes | no)
  telemetry_active_option="$SHARE_TELEMETRY_CHOICE"
  ;;
esac

telemetry_list_height="${#telemetry_options[@]}"
if [ "$telemetry_list_height" -lt 4 ]; then
  telemetry_list_height=4
fi

telemetry_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "$telemetry_list_height"
)

for telemetry_option in "${telemetry_options[@]}"; do
  telemetry_args+=("$telemetry_option" "")
  if [ "$telemetry_option" == "$telemetry_active_option" ]; then
    telemetry_args+=("ON")
  else
    telemetry_args+=("OFF")
  fi
done

telemetry_choice=""
if ! tui_nav_capture telemetry_choice "${telemetry_args[@]}"; then
  return 0
fi

case "$telemetry_choice" in
yes | no)
  SHARE_TELEMETRY_CHOICE="$telemetry_choice"
  ;;
*)
  SHARE_TELEMETRY_CHOICE="$telemetry_active_option"
  ;;
esac
export SHARE_TELEMETRY_CHOICE

if [ "$SHARE_TELEMETRY_CHOICE" == "yes" ]; then
  export SHARE_TELEMETRY="true"
else
  export SHARE_TELEMETRY="false"
fi

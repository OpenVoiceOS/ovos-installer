#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh

# shellcheck source=tui/locales/en-us/uninstall.sh
source "tui/locales/$LOCALE/uninstall.sh"

# A radiolist rather than a yes/no box: the cancel button is then free to mean
# "Back", so this screen is part of the same flow as the rest and not a wall
# an existing installation runs into.
uninstall_options=(no yes)
uninstall_active_option="no"
if [ "${CONFIRM_UNINSTALL:-false}" == "true" ]; then
  uninstall_active_option="yes"
fi

uninstall_list_height="${#uninstall_options[@]}"
if [ "$uninstall_list_height" -lt 4 ]; then
  uninstall_list_height=4
fi

uninstall_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  --notags
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "$uninstall_list_height"
)

for uninstall_option in "${uninstall_options[@]}"; do
  # The tag is the value, the item is what the user reads.
  if [ "$uninstall_option" == "yes" ]; then
    uninstall_args+=("$uninstall_option" "$YES_BUTTON")
  else
    uninstall_args+=("$uninstall_option" "$NO_BUTTON")
  fi
  if [ "$uninstall_option" == "$uninstall_active_option" ]; then
    uninstall_args+=("ON")
  else
    uninstall_args+=("OFF")
  fi
done

uninstall_choice=""
if ! tui_nav_capture uninstall_choice "${uninstall_args[@]}"; then
  return 0
fi

if [ "$uninstall_choice" == "yes" ]; then
  export CONFIRM_UNINSTALL="true"
else
  export CONFIRM_UNINSTALL="false"
fi

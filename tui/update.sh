#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh

# shellcheck source=tui/locales/en-us/update.sh
source "tui/locales/$LOCALE/update.sh"

# See tui/uninstall.sh: a radiolist so the cancel button can mean "Back".
update_options=(yes no)
update_active_option="yes"

update_list_height="${#update_options[@]}"
if [ "$update_list_height" -lt 4 ]; then
  update_list_height=4
fi

update_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  --notags
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "$update_list_height"
)

for update_option in "${update_options[@]}"; do
  if [ "$update_option" == "yes" ]; then
    update_args+=("$update_option" "$YES_BUTTON")
  else
    update_args+=("$update_option" "$NO_BUTTON")
  fi
  if [ "$update_option" == "$update_active_option" ]; then
    update_args+=("ON")
  else
    update_args+=("OFF")
  fi
done

update_choice=""
if ! tui_nav_capture update_choice "${update_args[@]}"; then
  return 0
fi

# Neither uninstalling nor updating leaves the installer with nothing to do.
if [ "$update_choice" != "yes" ]; then
  tui_nav_quit
fi

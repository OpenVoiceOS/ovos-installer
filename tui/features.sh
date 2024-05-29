#!/bin/env bash

# shellcheck source=locales/en-us/features.sh
source "tui/locales/$LOCALE/features.sh"

export FEATURE_GUI="false"
export FEATURE_SKILLS="false"
export FEATURE_EXTRA_SKILLS="false"

features=("skills" "$SKILL_DESCRIPTION" ON)
features+=("extra skills" "$EXTRA_SKILL_DESCRIPTION" OFF)
if [[ "$RASPBERRYPI_MODEL" != *"Raspberry Pi 3"* ]] && [[ "$KERNEL" != *"microsoft"* ]] && [ "$PROFILE" != "server" ]; then
  features+=("gui" "$GUI_DESCRIPTION" OFF)
fi

OVOS_FEATURES=$(whiptail --separate-output --title "$TITLE" \
  --checklist "$CONTENT" --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --yes-button "$OK_BUTTON" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "${#features[@]}" "${features[@]}" 3>&1 1>&2 2>&3)

exit_status=$?

if [ "$exit_status" -ne 0 ]; then
  source tui/profiles.sh
  if [[ "$PROFILE" == "satellite" ]]; then
    source tui/satellite/main.sh
  else
    source tui/features.sh
  fi
fi

for FEATURE in $OVOS_FEATURES; do
  case "$FEATURE" in
  "gui")
    export FEATURE_GUI="true"
    ;;
  "skills")
    export FEATURE_SKILLS="true"
    ;;
  "extra skills")
    export FEATURE_EXTRA_SKILLS="true"
    ;;
  esac
done

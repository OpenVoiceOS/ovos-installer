#!/bin/env bash

# shellcheck source=locales/en-us/features.sh
source "tui/locales/$LOCALE/features.sh"

export FEATURE_GUI="false"
export FEATURE_SKILLS="false"

features=("skills" "$SKILL_DESCRIPTION" ON)
if [[ "$RASPBERRYPI_MODEL" != *"Raspberry Pi 3"* ]]; then
  features+=("gui" "$GUI_DESCRIPTION" OFF)
fi

OVOS_FEATURES=$(whiptail --separate-output --title "$TITLE" \
  --checklist "$CONTENT" --cancel-button "$CANCEL_BUTTON" --ok-button "$OK_BUTTON" --yes-button "$OK_BUTTON" 25 80 "${#features[@]}" "${features[@]}" 3>&1 1>&2 2>&3)

for FEATURE in $OVOS_FEATURES; do
  case "$FEATURE" in
  "gui")
    export FEATURE_GUI="true"
    ;;
  "skills")
    export FEATURE_SKILLS="true"
    ;;
  esac
done

exit_status=$?
if [ "$exit_status" -eq 1 ]; then
  exit 1
fi

#!/bin/env bash

##TODO - ask for gender and online prefrence and find regin using tekemetry ip (countryccode-regioncode)

export CONFIG_AUTOCONFIG = "true"
export CONFIG_MODE = "online"
export AUTOCONFIG = "true"

# shellcheck source=locales/en-us/autoconfig.sh
source "tui/locales/$LOCALE/autoconfig.sh"

whiptail --yesno --no-button "$NO_BUTTON" --yes-button "$YES_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"


export CONFIG_MODE = "online"
export CONFIG_GENDER = "female"

features=("skills" "$SKILL_DESCRIPTION" ON)
features+=("extra-skills" "$EXTRA_SKILL_DESCRIPTION" OFF)
if [[ "$RASPBERRYPI_MODEL" != *"Raspberry Pi 3"* ]] && [[ "$KERNEL" != *"microsoft"* ]] && [ "$PROFILE" != "server" ]; then
  features+=("gui" "$GUI_DESCRIPTION" OFF)
fi

OVOS_FEATURES=$(whiptail --separate-output --title "$TITLE" \
  --checklist "$CONTENT" --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --yes-button "$OK_BUTTON" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "${#features[@]}" "${features[@]}" 3>&1 1>&2 2>&3)

exit_status=$?

if [ "$exit_status" -ne 0 ]; then
  source tui/telemetry.sh
fi

for FEATURE in $OVOS_FEATURES; do
  case "$FEATURE" in
  "gui")
    export FEATURE_GUI="true"
    ;;
  "skills")
    export FEATURE_SKILLS="true"
    ;;
  "extra-skills")
    export FEATURE_EXTRA_SKILLS="true"
    ;;
  esac
done


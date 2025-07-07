#!/bin/env bash

# shellcheck source=locales/en-us/features.sh
source "tui/locales/$LOCALE/features.sh"

export FEATURE_GUI="false"
export FEATURE_SKILLS="false"
export FEATURE_EXTRA_SKILLS="false"

declare -a features
features=("skills" "$SKILL_DESCRIPTION" ON)
features+=("extra-skills" "$EXTRA_SKILL_DESCRIPTION" OFF)
if [[ "$RASPBERRYPI_MODEL" != *"Raspberry Pi 3"* ]] && [[ "$KERNEL" != *"microsoft"* ]] && [ "$PROFILE" != "server" ]; then
  features+=("gui" "$GUI_DESCRIPTION" OFF)
fi

if [ -f "$INSTALLER_STATE_FILE" ]; then
  if jq -e '.features|any(. == "skills")' "$INSTALLER_STATE_FILE" &>>"$LOG_FILE"; then
    features=("skills" "$SKILL_DESCRIPTION" ON)
  else
    features=("skills" "$SKILL_DESCRIPTION" OFF)
  fi
  if jq -e '.features|any(. == "extra-skills")' "$INSTALLER_STATE_FILE" &>>"$LOG_FILE"; then
    features+=("extra-skills" "$EXTRA_SKILL_DESCRIPTION" ON)
  else
    features+=("extra-skills" "$EXTRA_SKILL_DESCRIPTION" OFF)
  fi
  if jq -e '.features|any(. == "gui")' "$INSTALLER_STATE_FILE" &>>"$LOG_FILE"; then
    features+=("gui" "$GUI_DESCRIPTION" ON)
  else
    features+=("gui" "$GUI_DESCRIPTION" OFF)
  fi
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

declare -a FEATURES_STATE
for FEATURE in $OVOS_FEATURES; do
  case "$FEATURE" in
  "gui")
    export FEATURE_GUI="true"
    FEATURES_STATE+=("gui")
    ;;
  "skills")
    export FEATURE_SKILLS="true"
    FEATURES_STATE+=("skills")
    ;;
  "extra-skills")
    export FEATURE_EXTRA_SKILLS="true"
    FEATURES_STATE+=("extra-skills")
    ;;
  esac
done

if [ "$exit_status" -ne 1 ]; then
  jq -en '.features += $ARGS.positional' --args "${FEATURES_STATE[@]}" >"$TEMP_FEATURES_FILE"
  jq -es '.[0] * .[1] * . [2]' "$TEMP_PROFILE_FILE" "$TEMP_FEATURES_FILE" "$TEMP_CHANNEL_FILE" >"$INSTALLER_STATE_FILE"
  rm "$TEMP_FEATURES_FILE" "$TEMP_PROFILE_FILE" "$TEMP_CHANNEL_FILE"
fi

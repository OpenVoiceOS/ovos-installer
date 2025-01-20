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

features_state_file="$RUN_AS_HOME/.local/state/ovos/features.json"
if [ -f "$features_state_file" ]; then
  if jq -e '.features|any(. == "skills")' "$features_state_file"; then
    features=("skills" "$SKILL_DESCRIPTION" ON)
  else
    features=("skills" "$SKILL_DESCRIPTION" OFF)
  fi
  if jq -e '.features|any(. == "extra-skills")' "$features_state_file"; then
    features+=("extra-skills" "$EXTRA_SKILL_DESCRIPTION" ON)
  else
    features+=("extra-skills" "$EXTRA_SKILL_DESCRIPTION" OFF)
  fi
  if jq -e '.features|any(. == "gui")' "$features_state_file"; then
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

jq -n '.features += $ARGS.positional' --args "${FEATURES_STATE[@]}" > "$features_state_file"

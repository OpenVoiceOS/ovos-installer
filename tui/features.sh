#!/usr/bin/env bash
# shellcheck source=tui/locales/en-us/features.sh
source "tui/locales/$LOCALE/features.sh"

export FEATURE_SKILLS="false"
export FEATURE_EXTRA_SKILLS="false"
export FEATURE_GUI="false"
export FEATURE_HOMEASSISTANT="false"
export FEATURE_LLM="false"
export HOMEASSISTANT_URL="${HOMEASSISTANT_URL:-}"
export LLM_API_URL="${LLM_API_URL:-}"
export LLM_PERSONA="${LLM_PERSONA:-helpful, creative, clever, and very friendly.}"

_mark2_or_devkit_detected="false"
_gui_supported="false"
_gui_default_state="OFF"
for _device in "${DETECTED_DEVICES[@]}"; do
  if [ "$_device" == "tas5806" ]; then
    _mark2_or_devkit_detected="true"
    break
  fi
done
if [[ "$_mark2_or_devkit_detected" == "true" ]] && \
  [[ "${PROFILE:-}" != "server" ]] && \
  [[ "${PROFILE:-}" != "satellite" ]] && \
  [[ "${DISTRO_NAME:-}" == "debian" ]] && \
  { [[ "${DISTRO_VERSION_ID:-}" == 13* ]] || [[ "${DISTRO_VERSION:-}" =~ [Tt]rixie ]]; }; then
  _gui_supported="true"
  _gui_default_state="ON"
fi
_gui_description="${GUI_DESCRIPTION:-Enable OVOS GUI support}"
if [ "${_gui_supported}" == "true" ]; then
  _gui_description="${GUI_DESCRIPTION:-Enable OVOS GUI support (Mark II/DevKit on Debian Trixie)}"
  if [ "${_gui_default_state}" == "ON" ]; then
    export FEATURE_GUI="true"
  fi
fi

_ha_supported="false"
if [[ "${METHOD:-virtualenv}" == "virtualenv" || "${METHOD:-virtualenv}" == "containers" ]] && \
  [[ "${PROFILE:-}" != "server" ]] && \
  [[ "${PROFILE:-}" != "satellite" ]]; then
  _ha_supported="true"
fi

_llm_supported="false"
if [[ "${METHOD:-virtualenv}" == "virtualenv" || "${METHOD:-virtualenv}" == "containers" ]] && \
  [[ "${PROFILE:-}" != "server" ]] && \
  [[ "${PROFILE:-}" != "satellite" ]]; then
  _llm_supported="true"
fi

declare -a features
features=("skills" "$SKILL_DESCRIPTION" "ON")
features+=("extra-skills" "$EXTRA_SKILL_DESCRIPTION" "OFF")
if [ "${_gui_supported}" == "true" ]; then
  features+=("gui" "${_gui_description}" "${_gui_default_state}")
fi
if [ "${_ha_supported}" == "true" ]; then
  features+=("homeassistant" "${HOMEASSISTANT_DESCRIPTION:-Enable Home Assistant integration (requires URL + token)}" "OFF")
fi
if [ "${_llm_supported}" == "true" ]; then
  features+=("llm" "${LLM_DESCRIPTION:-Enable OVOS Persona LLM fallback (requires API URL + key + model + persona)}" "OFF")
fi

if [ -f "$INSTALLER_STATE_FILE" ] && \
  jq -e '(.features? | type) == "array"' "$INSTALLER_STATE_FILE" >/dev/null 2>>"$LOG_FILE"; then
  if jq -e '.features|any(. == "skills")' "$INSTALLER_STATE_FILE" >/dev/null 2>>"$LOG_FILE"; then
    features=("skills" "$SKILL_DESCRIPTION" "ON")
  else
    features=("skills" "$SKILL_DESCRIPTION" "OFF")
  fi
  if jq -e '.features|any(. == "extra-skills")' "$INSTALLER_STATE_FILE" >/dev/null 2>>"$LOG_FILE"; then
    features+=("extra-skills" "$EXTRA_SKILL_DESCRIPTION" "ON")
  else
    features+=("extra-skills" "$EXTRA_SKILL_DESCRIPTION" "OFF")
  fi
  if [ "${_gui_supported}" == "true" ]; then
    if jq -e '.feature_gui_selected | type == "boolean"' "$INSTALLER_STATE_FILE" >/dev/null 2>>"$LOG_FILE"; then
      if jq -e '.feature_gui_selected == true' "$INSTALLER_STATE_FILE" >/dev/null 2>>"$LOG_FILE"; then
        features+=("gui" "${_gui_description}" "ON")
        export FEATURE_GUI="true"
      else
        features+=("gui" "${_gui_description}" "OFF")
        export FEATURE_GUI="false"
      fi
    elif jq -e '.features|any(. == "gui")' "$INSTALLER_STATE_FILE" >/dev/null 2>>"$LOG_FILE"; then
      features+=("gui" "${_gui_description}" "ON")
      export FEATURE_GUI="true"
    else
      # Legacy state without explicit GUI selection should follow Mark II default.
      features+=("gui" "${_gui_description}" "${_gui_default_state}")
      if [ "${_gui_default_state}" == "ON" ]; then
        export FEATURE_GUI="true"
      else
        export FEATURE_GUI="false"
      fi
    fi
  fi
  if [ "${_ha_supported}" == "true" ]; then
    if jq -e '.features|any(. == "homeassistant")' "$INSTALLER_STATE_FILE" >/dev/null 2>>"$LOG_FILE"; then
      features+=("homeassistant" "${HOMEASSISTANT_DESCRIPTION:-Enable Home Assistant integration (requires URL + token)}" "ON")
    else
      features+=("homeassistant" "${HOMEASSISTANT_DESCRIPTION:-Enable Home Assistant integration (requires URL + token)}" "OFF")
    fi
  fi
  if [ "${_llm_supported}" == "true" ]; then
    if jq -e '.features|any(. == "llm")' "$INSTALLER_STATE_FILE" >/dev/null 2>>"$LOG_FILE"; then
      features+=("llm" "${LLM_DESCRIPTION:-Enable OVOS Persona LLM fallback (requires API URL + key + model + persona)}" "ON")
    else
      features+=("llm" "${LLM_DESCRIPTION:-Enable OVOS Persona LLM fallback (requires API URL + key + model + persona)}" "OFF")
    fi
  fi
fi

# Whiptail requires (tag item status)*. If anything corrupts the list, fall back
# to a safe default instead of rendering a blank window.
if [ "${#features[@]}" -lt 3 ] || [ $(( ${#features[@]} % 3 )) -ne 0 ]; then
  features=(
    "skills" "$SKILL_DESCRIPTION" "ON"
    "extra-skills" "$EXTRA_SKILL_DESCRIPTION" "OFF"
  )
  if [ "${_gui_supported}" == "true" ]; then
    features+=("gui" "${_gui_description}" "${_gui_default_state}")
  fi
  if [ "${_ha_supported}" == "true" ]; then
    features+=("homeassistant" "${HOMEASSISTANT_DESCRIPTION:-Enable Home Assistant integration (requires URL + token)}" "OFF")
  fi
  if [ "${_llm_supported}" == "true" ]; then
    features+=("llm" "${LLM_DESCRIPTION:-Enable OVOS Persona LLM fallback (requires API URL + key + model + persona)}" "OFF")
  fi
fi

list_height=$((${#features[@]} / 3))
if [ "$list_height" -lt 1 ]; then
  list_height=1
fi
if [ "$list_height" -lt 4 ]; then
  list_height=4
fi

if [ "${DEBUG:-false}" == "true" ]; then
  {
    printf '[debug] features: options=%s list_height=%s\n' "$(( ${#features[@]} / 3 ))" "$list_height"
    printf '[debug] features: args=%s\n' "${features[*]}"
  } >>"$LOG_FILE" 2>/dev/null || true
fi

OVOS_FEATURES=$(whiptail --separate-output --title "$TITLE" \
  --checklist "$CONTENT" --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "$list_height" "${features[@]}" 3>&1 1>&2 2>&3)

exit_status=$?

if [ "$exit_status" -ne 0 ]; then
  source tui/profiles.sh
  if [[ "$PROFILE" == "satellite" ]]; then
    # Satellite doesn't have selectable features; collect satellite settings next.
    export FEATURE_GUI="false" FEATURE_SKILLS="false" FEATURE_EXTRA_SKILLS="false" FEATURE_LLM="false"
    source tui/satellite/main.sh
    return
fi
  source tui/features.sh
  return
fi

FEATURES_STATE=()
if [ "${_gui_supported}" == "true" ]; then
  export FEATURE_GUI="false"
fi
if [ "${_llm_supported}" == "true" ]; then
  export FEATURE_LLM="false"
fi
for FEATURE in $OVOS_FEATURES; do
  case "$FEATURE" in
  "skills")
    export FEATURE_SKILLS="true"
    FEATURES_STATE+=("skills")
    ;;
  "extra-skills")
    export FEATURE_EXTRA_SKILLS="true"
    FEATURES_STATE+=("extra-skills")
    ;;
  "gui")
    export FEATURE_GUI="true"
    FEATURES_STATE+=("gui")
    ;;
  "homeassistant")
    # Collect Home Assistant details; only enable if fully configured.
    # shellcheck source=tui/homeassistant.sh
    source tui/homeassistant.sh
    if [ "${HOMEASSISTANT_BACK:-false}" == "true" ]; then
      unset HOMEASSISTANT_BACK
      source tui/features.sh
      return
    fi
    if [ "${FEATURE_HOMEASSISTANT}" == "true" ]; then
      FEATURES_STATE+=("homeassistant")
    fi
    ;;
  "llm")
    # Collect LLM details; only enable if fully configured.
    # shellcheck source=tui/llm.sh
    source tui/llm.sh
    if [ "${LLM_BACK:-false}" == "true" ]; then
      unset LLM_BACK
      source tui/features.sh
      return
    fi
    if [ "${FEATURE_LLM}" == "true" ]; then
      FEATURES_STATE+=("llm")
    fi
    ;;
  esac
done

# Persist selection (used for defaults when navigating back or re-running).
features_json="$(jq -c -n --args '$ARGS.positional' "${FEATURES_STATE[@]}" 2>>"$LOG_FILE")"
state_tmp="$(mktemp)"
_feature_gui_selected_json="null"
if [ "${_gui_supported}" == "true" ]; then
  if [ "${FEATURE_GUI}" == "true" ]; then
    _feature_gui_selected_json="true"
  else
    _feature_gui_selected_json="false"
  fi
fi
if [ -f "$INSTALLER_STATE_FILE" ] && \
  jq --argjson features "$features_json" \
    --argjson feature_gui_selected "$_feature_gui_selected_json" \
    'if type=="object" then . else {} end
     | .features = $features
     | if $feature_gui_selected == null then . else .feature_gui_selected = $feature_gui_selected end' \
    "$INSTALLER_STATE_FILE" >"$state_tmp" 2>>"$LOG_FILE"; then
  mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
else
  jq -n --argjson features "$features_json" --argjson feature_gui_selected "$_feature_gui_selected_json" \
    '{features: $features} | if $feature_gui_selected == null then . else .feature_gui_selected = $feature_gui_selected end' \
    >"$state_tmp" 2>>"$LOG_FILE" && \
    mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
fi

# Keep state writable by the target user when running under sudo/root.
if [ -n "${RUN_AS:-}" ] && [ -f "$INSTALLER_STATE_FILE" ]; then
  chown "$RUN_AS":"$(id -ng "$RUN_AS" 2>>"$LOG_FILE")" "$INSTALLER_STATE_FILE" &>>"$LOG_FILE" || true
fi

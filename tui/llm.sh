#!/usr/bin/env bash
# shellcheck source=tui/locales/en-us/llm.sh
_llm_locale_file="tui/locales/$LOCALE/llm.sh"
if [ -f "$_llm_locale_file" ]; then
  source "$_llm_locale_file"
else
  source "tui/locales/en-us/llm.sh"
fi

: "${LLM_TITLE_SETUP:=Open Voice OS Installation - LLM}"
: "${LLM_TITLE_EXISTING:=Open Voice OS Installation - Existing LLM Settings}"
: "${LLM_TITLE_URL:=Open Voice OS Installation - LLM API URL}"
: "${LLM_TITLE_KEY:=Open Voice OS Installation - LLM API Key}"
: "${LLM_TITLE_PERSONA:=Open Voice OS Installation - LLM Persona}"
: "${LLM_TITLE_INVALID:=Open Voice OS Installation - Invalid LLM Configuration}"
: "${LLM_CONTENT_HAVE_DETAILS:=Please provide API URL, API key, and persona text.}"
: "${LLM_CONTENT_EXISTING:=Existing LLM persona configuration detected.}"
: "${LLM_CONTENT_URL:=Please enter your OpenAI-compatible API URL.}"
: "${LLM_CONTENT_KEY:=Please enter your LLM API key.}"
: "${LLM_CONTENT_KEY_KEEP_EXISTING:=Leave empty to keep your existing key.}"
: "${LLM_CONTENT_PERSONA:=Please enter the persona prompt used by ovos-persona.}"
: "${LLM_CONTENT_MISSING_INFO:=Some required LLM information is missing.}"
: "${LLM_CONTENT_INVALID_URL:=Invalid URL.}"

_llm_restore_xtrace="false"
case "$-" in
*x*)
  _llm_restore_xtrace="true"
  set +x
  ;;
esac
restore_llm_xtrace() {
  if [ "$_llm_restore_xtrace" == "true" ]; then
    set -x
  fi
}

normalize_llm_url() {
  local llm_url="$1"

  llm_url="${llm_url//[[:space:]]/}"
  llm_url="${llm_url%/}"
  if [ -z "$llm_url" ]; then
    printf '%s' ""
    return
  fi

  if [[ "$llm_url" != http://* && "$llm_url" != https://* ]]; then
    if [[ "$llm_url" == *"://"* ]]; then
      printf '%s' ""
      return
    fi
    llm_url="http://${llm_url}"
  fi

  if [[ "$llm_url" =~ ^https?://[^/]+(/.*)?$ ]]; then
    printf '%s' "$llm_url"
  else
    printf '%s' ""
  fi
}

persist_llm_state() {
  local state_tmp
  state_tmp="$(mktemp)"
  if [ -f "$INSTALLER_STATE_FILE" ]; then
    if jq --arg api_url "$LLM_API_URL" --arg persona "$LLM_PERSONA" \
      'if type=="object" then . else {} end | .llm = ((.llm // {}) + {api_url: $api_url, persona: $persona})' \
      "$INSTALLER_STATE_FILE" >"$state_tmp" 2>>"$LOG_FILE"; then
      mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
    else
      printf '%s\n' "[warn] llm: invalid state file; skipping persistence: $INSTALLER_STATE_FILE" >>"$LOG_FILE" 2>/dev/null || true
      rm -f "$state_tmp"
    fi
  else
    if jq -n --arg api_url "$LLM_API_URL" --arg persona "$LLM_PERSONA" \
      '{llm: {api_url: $api_url, persona: $persona}}' >"$state_tmp" 2>>"$LOG_FILE"; then
      mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
    else
      rm -f "$state_tmp"
    fi
  fi

  if [ -n "${RUN_AS:-}" ] && [ -f "$INSTALLER_STATE_FILE" ]; then
    chown "$RUN_AS":"$(id -ng "$RUN_AS" 2>>"$LOG_FILE")" "$INSTALLER_STATE_FILE" &>>"$LOG_FILE" || true
  fi
}

export FEATURE_LLM="false"
export LLM_API_URL="${LLM_API_URL:-}"
export LLM_PERSONA="${LLM_PERSONA:-helpful, creative, clever, and very friendly.}"
LLM_API_KEY="${LLM_API_KEY:-}"

if [ -n "${LLM_API_URL}" ] && [ -n "${LLM_API_KEY}" ] && [ -n "${LLM_PERSONA}" ]; then
  export FEATURE_LLM="true"
  restore_llm_xtrace
  return
fi

llm_persona_file=""
case "${METHOD:-virtualenv}" in
containers)
  llm_persona_file="${RUN_AS_HOME:-$HOME}/ovos/config/persona/ovos-installer-llm.json"
  ;;
virtualenv | *)
  llm_persona_file="${RUN_AS_HOME:-$HOME}/.config/ovos_persona/ovos-installer-llm.json"
  ;;
esac

llm_existing_url=""
llm_existing_key=""
llm_existing_persona=""
if [ -f "$llm_persona_file" ]; then
  llm_existing_url="$(jq -r '.["ovos-solver-openai-plugin"].api_url // .["ovos-openai-plugin"].api_url // .solvers["ovos-solver-openai-plugin"].api_url // .solvers["ovos-openai-plugin"].api_url // ""' "$llm_persona_file" 2>>"$LOG_FILE" || true)"
  llm_existing_key="$(jq -r '.["ovos-solver-openai-plugin"].key // .["ovos-openai-plugin"].key // .solvers["ovos-solver-openai-plugin"].key // .solvers["ovos-openai-plugin"].key // ""' "$llm_persona_file" 2>>"$LOG_FILE" || true)"
  llm_existing_persona="$(jq -r '.["ovos-solver-openai-plugin"].persona // .["ovos-openai-plugin"].persona // .prompt // ""' "$llm_persona_file" 2>>"$LOG_FILE" || true)"
fi

if [ -n "$llm_existing_url" ] && [ -n "$llm_existing_key" ] && [ -n "$llm_existing_persona" ]; then
  _llm_existing_prompt="${LLM_CONTENT_EXISTING//__URL__/$llm_existing_url}"
  whiptail --yesno --yes-button "$YES_BUTTON" --no-button "$NO_BUTTON" \
    --title "$LLM_TITLE_EXISTING" "$_llm_existing_prompt" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

  exit_status=$?
  if [ "$exit_status" -eq 0 ]; then
    export FEATURE_LLM="true"
    export LLM_API_URL="$llm_existing_url"
    LLM_API_KEY="$llm_existing_key"
    export LLM_PERSONA="$llm_existing_persona"
    persist_llm_state
    restore_llm_xtrace
    return
  fi
  if [ "$exit_status" -eq 255 ]; then
    export FEATURE_LLM="false"
    export LLM_API_URL=""
    LLM_API_KEY=""
    export LLM_PERSONA=""
    export LLM_BACK="true"
    restore_llm_xtrace
    return
  fi
fi

whiptail --msgbox --title "$LLM_TITLE_SETUP" "$LLM_CONTENT_HAVE_DETAILS" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

llm_url_default=""
if [ -n "$llm_existing_url" ]; then
  llm_url_default="$llm_existing_url"
elif [ -f "$INSTALLER_STATE_FILE" ]; then
  llm_url_default="$(jq -r '.llm.api_url // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE" || true)"
fi
if [ -z "$llm_url_default" ]; then
  llm_url_default="${LLM_API_URL:-https://llama.smartgic.io/v1}"
fi

llm_persona_default=""
if [ -n "$llm_existing_persona" ]; then
  llm_persona_default="$llm_existing_persona"
elif [ -f "$INSTALLER_STATE_FILE" ]; then
  llm_persona_default="$(jq -r '.llm.persona // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE" || true)"
fi
if [ -z "$llm_persona_default" ]; then
  llm_persona_default="${LLM_PERSONA:-helpful, creative, clever, and very friendly.}"
fi

while :; do
  llm_url_input="$(whiptail --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$LLM_TITLE_URL" "$LLM_CONTENT_URL" 25 80 "$llm_url_default" 3>&1 1>&2 2>&3)"

  exit_status=$?
  if [ "$exit_status" -ne 0 ]; then
    export LLM_BACK="true"
    export FEATURE_LLM="false"
    export LLM_API_URL=""
    LLM_API_KEY=""
    export LLM_PERSONA=""
    restore_llm_xtrace
    return
  fi

  LLM_API_URL="$(normalize_llm_url "$llm_url_input")"
  if [ -z "$LLM_API_URL" ]; then
    whiptail --msgbox --title "$LLM_TITLE_INVALID" "$LLM_CONTENT_INVALID_URL" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  llm_url_default="$LLM_API_URL"
  export LLM_API_URL
  break
done

while :; do
  _llm_key_prompt="$LLM_CONTENT_KEY"
  if [ -n "$llm_existing_key" ]; then
    _llm_key_prompt="${_llm_key_prompt}
${LLM_CONTENT_KEY_KEEP_EXISTING}"
  fi

  LLM_API_KEY="$(whiptail --passwordbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$LLM_TITLE_KEY" "$_llm_key_prompt" 25 80 3>&1 1>&2 2>&3)"

  exit_status=$?
  if [ "$exit_status" -eq 0 ] && [ -z "$LLM_API_KEY" ] && [ -n "$llm_existing_key" ]; then
    LLM_API_KEY="$llm_existing_key"
  fi
  if [ "$exit_status" -ne 0 ]; then
    export LLM_BACK="true"
    export FEATURE_LLM="false"
    export LLM_API_URL=""
    LLM_API_KEY=""
    export LLM_PERSONA=""
    restore_llm_xtrace
    return
  fi
  if [ -z "$LLM_API_KEY" ]; then
    whiptail --msgbox --title "$LLM_TITLE_INVALID" "$LLM_CONTENT_MISSING_INFO" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  break
done

while :; do
  LLM_PERSONA="$(whiptail --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$LLM_TITLE_PERSONA" "$LLM_CONTENT_PERSONA" 25 80 "$llm_persona_default" 3>&1 1>&2 2>&3)"

  exit_status=$?
  if [ "$exit_status" -ne 0 ]; then
    export LLM_BACK="true"
    export FEATURE_LLM="false"
    export LLM_API_URL=""
    LLM_API_KEY=""
    export LLM_PERSONA=""
    restore_llm_xtrace
    return
  fi
  LLM_PERSONA="${LLM_PERSONA#"${LLM_PERSONA%%[![:space:]]*}"}"
  LLM_PERSONA="${LLM_PERSONA%"${LLM_PERSONA##*[![:space:]]}"}"
  if [ -z "$LLM_PERSONA" ]; then
    whiptail --msgbox --title "$LLM_TITLE_INVALID" "$LLM_CONTENT_MISSING_INFO" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  export LLM_PERSONA
  break
done

export FEATURE_LLM="true"
persist_llm_state
restore_llm_xtrace

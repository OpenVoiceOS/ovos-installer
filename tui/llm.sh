#!/usr/bin/env bash
# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh
# shellcheck source=utils/llm_defaults.sh
source "utils/llm_defaults.sh"
_llm_bootstrap_default_persona="$LLM_DEFAULT_PERSONA"
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
: "${LLM_TITLE_MODEL:=Open Voice OS Installation - LLM Model}"
: "${LLM_TITLE_PERSONA:=Open Voice OS Installation - LLM Assistant Style}"
: "${LLM_TITLE_MAX_TOKENS:=Open Voice OS Installation - LLM Reply Length}"
: "${LLM_TITLE_TEMPERATURE:=Open Voice OS Installation - LLM Creativity}"
: "${LLM_TITLE_TOP_P:=Open Voice OS Installation - LLM Focus}"
: "${LLM_TITLE_INVALID:=Open Voice OS Installation - Invalid LLM Configuration}"
: "${LLM_CONTENT_HAVE_DETAILS:=Please provide API URL, API key, model, assistant style, reply length, creativity, and focus settings.}"
: "${LLM_CONTENT_EXISTING:=Existing LLM persona configuration detected.}"
: "${LLM_CONTENT_URL:=Please enter your OpenAI-compatible API URL.}"
: "${LLM_CONTENT_KEY:=Please enter your LLM API key.}"
: "${LLM_CONTENT_KEY_KEEP_EXISTING:=Leave empty to keep your existing key.}"
: "${LLM_CONTENT_MODEL:=Please enter the LLM model name to use.}"
: "${LLM_CONTENT_PERSONA:=Please enter the assistant style prompt used by ovos-persona.}"
: "${LLM_CONTENT_MAX_TOKENS:=Please enter the reply length budget for the model.}"
: "${LLM_CONTENT_TEMPERATURE:=Please enter the creativity level for the model.}"
: "${LLM_CONTENT_TOP_P:=Please enter the focus level for the model.}"
: "${LLM_CONTENT_MISSING_INFO:=Some required LLM information is missing.}"
: "${LLM_CONTENT_INVALID_URL:=Invalid URL.}"
: "${LLM_CONTENT_INVALID_MAX_TOKENS:=Invalid reply length. Please enter a whole number greater than 0.}"
: "${LLM_CONTENT_INVALID_TEMPERATURE:=Invalid creativity level. Please enter a number between 0 and 2.}"
: "${LLM_CONTENT_INVALID_TOP_P:=Invalid focus level. Please enter a number between 0 and 1.}"

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

cancel_llm_setup() {
  export LLM_BACK="true"
  export FEATURE_LLM="false"
  export LLM_API_URL=""
  LLM_API_KEY=""
  export LLM_MODEL=""
  export LLM_PERSONA=""
  export LLM_MAX_TOKENS=""
  export LLM_TEMPERATURE=""
  export LLM_TOP_P=""
  restore_llm_xtrace
}

trim_llm_input() {
  local llm_value="$1"
  llm_value="${llm_value#"${llm_value%%[![:space:]]*}"}"
  llm_value="${llm_value%"${llm_value##*[![:space:]]}"}"
  printf '%s' "$llm_value"
}

normalize_llm_persona_default() {
  local llm_value="$1"

  if [ -n "$llm_value" ] && [ "$llm_value" = "$_llm_bootstrap_default_persona" ] && \
    [ "$LLM_DEFAULT_PERSONA" != "$_llm_bootstrap_default_persona" ]; then
    printf '%s' "$LLM_DEFAULT_PERSONA"
  else
    printf '%s' "$llm_value"
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

normalize_llm_positive_int() {
  local llm_value
  llm_value="$(trim_llm_input "$1")"

  if [[ "$llm_value" =~ ^[0-9]+$ ]] && [ "$llm_value" -gt 0 ]; then
    printf '%s' "$llm_value"
  else
    printf '%s' ""
  fi
}

normalize_llm_decimal_in_range() {
  local llm_value min_value max_value
  llm_value="$(trim_llm_input "$1")"
  min_value="$2"
  max_value="$3"

  if awk -v value="$llm_value" -v min="$min_value" -v max="$max_value" '
    BEGIN {
      if (value == "") {
        exit 1
      }
      if (value ~ /^[0-9]+([.][0-9]+)?$/ || value ~ /^[.][0-9]+$/) {
        if ((value + 0) >= (min + 0) && (value + 0) <= (max + 0)) {
          exit 0
        }
      }
      exit 1
    }
  ' >/dev/null 2>&1; then
    printf '%s' "$llm_value"
  else
    printf '%s' ""
  fi
}

persist_llm_state() {
  local state_tmp
  state_tmp="$(mktemp)"
  if [ -f "$INSTALLER_STATE_FILE" ]; then
    if jq --arg api_url "$LLM_API_URL" --arg model "$LLM_MODEL" --arg persona "$LLM_PERSONA" \
      --argjson max_tokens "$LLM_MAX_TOKENS" --argjson temperature "$LLM_TEMPERATURE" --argjson top_p "$LLM_TOP_P" \
      'if type=="object" then . else {} end
       | .llm = ((.llm // {}) + {api_url: $api_url, model: $model, persona: $persona, max_tokens: $max_tokens, temperature: $temperature, top_p: $top_p})' \
      "$INSTALLER_STATE_FILE" >"$state_tmp" 2>>"$LOG_FILE"; then
      mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
    else
      printf '%s\n' "[warn] llm: invalid state file; skipping persistence: $INSTALLER_STATE_FILE" >>"$LOG_FILE" 2>/dev/null || true
      rm -f "$state_tmp"
    fi
  else
    if jq -n --arg api_url "$LLM_API_URL" --arg model "$LLM_MODEL" --arg persona "$LLM_PERSONA" \
      --argjson max_tokens "$LLM_MAX_TOKENS" --argjson temperature "$LLM_TEMPERATURE" --argjson top_p "$LLM_TOP_P" \
      '{llm: {api_url: $api_url, model: $model, persona: $persona, max_tokens: $max_tokens, temperature: $temperature, top_p: $top_p}}' >"$state_tmp" 2>>"$LOG_FILE"; then
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
export LLM_MODEL="${LLM_MODEL:-}"
export LLM_PERSONA="$(normalize_llm_persona_default "${LLM_PERSONA:-$LLM_DEFAULT_PERSONA}")"
export LLM_MAX_TOKENS="${LLM_MAX_TOKENS:-$LLM_DEFAULT_MAX_TOKENS}"
export LLM_TEMPERATURE="${LLM_TEMPERATURE:-$LLM_DEFAULT_TEMPERATURE}"
export LLM_TOP_P="${LLM_TOP_P:-$LLM_DEFAULT_TOP_P}"
LLM_API_KEY="${LLM_API_KEY:-}"
LLM_API_URL="$(normalize_llm_url "$LLM_API_URL")"
LLM_MAX_TOKENS="$(normalize_llm_positive_int "$LLM_MAX_TOKENS")"
LLM_TEMPERATURE="$(normalize_llm_decimal_in_range "$LLM_TEMPERATURE" "0" "2")"
LLM_TOP_P="$(normalize_llm_decimal_in_range "$LLM_TOP_P" "0" "1")"

if [ -n "${LLM_API_URL}" ] && [ -n "${LLM_API_KEY}" ] && [ -n "${LLM_MODEL}" ] && [ -n "${LLM_PERSONA}" ] && \
  [ -n "${LLM_MAX_TOKENS}" ] && [ -n "${LLM_TEMPERATURE}" ] && [ -n "${LLM_TOP_P}" ]; then
  export FEATURE_LLM="true"
  persist_llm_state
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
llm_existing_model=""
llm_existing_persona=""
llm_existing_max_tokens=""
llm_existing_temperature=""
llm_existing_top_p=""
if [ -f "$llm_persona_file" ]; then
  llm_existing_url="$(jq -r '.["ovos-solver-openai-plugin"].api_url // .["ovos-openai-plugin"].api_url // .solvers["ovos-solver-openai-plugin"].api_url // .solvers["ovos-openai-plugin"].api_url // ""' "$llm_persona_file" 2>>"$LOG_FILE" || true)"
  llm_existing_key="$(jq -r '.["ovos-solver-openai-plugin"].key // .["ovos-openai-plugin"].key // .solvers["ovos-solver-openai-plugin"].key // .solvers["ovos-openai-plugin"].key // ""' "$llm_persona_file" 2>>"$LOG_FILE" || true)"
  llm_existing_model="$(jq -r '.["ovos-solver-openai-plugin"].model // .["ovos-openai-plugin"].model // .solvers["ovos-solver-openai-plugin"].model // .solvers["ovos-openai-plugin"].model // .["ovos-solver-openai-plugin"].model_name // .["ovos-openai-plugin"].model_name // .solvers["ovos-solver-openai-plugin"].model_name // .solvers["ovos-openai-plugin"].model_name // ""' "$llm_persona_file" 2>>"$LOG_FILE" || true)"
  llm_existing_persona="$(jq -r '.["ovos-solver-openai-plugin"].system_prompt // .["ovos-openai-plugin"].system_prompt // .solvers["ovos-solver-openai-plugin"].system_prompt // .solvers["ovos-openai-plugin"].system_prompt // .["ovos-solver-openai-plugin"].persona // .["ovos-openai-plugin"].persona // .solvers["ovos-solver-openai-plugin"].persona // .solvers["ovos-openai-plugin"].persona // .prompt // ""' "$llm_persona_file" 2>>"$LOG_FILE" || true)"
  llm_existing_max_tokens="$(jq -r '.["ovos-solver-openai-plugin"].max_tokens // .["ovos-openai-plugin"].max_tokens // .solvers["ovos-solver-openai-plugin"].max_tokens // .solvers["ovos-openai-plugin"].max_tokens // ""' "$llm_persona_file" 2>>"$LOG_FILE" || true)"
  llm_existing_temperature="$(jq -r '.["ovos-solver-openai-plugin"].temperature // .["ovos-openai-plugin"].temperature // .solvers["ovos-solver-openai-plugin"].temperature // .solvers["ovos-openai-plugin"].temperature // ""' "$llm_persona_file" 2>>"$LOG_FILE" || true)"
  llm_existing_top_p="$(jq -r '.["ovos-solver-openai-plugin"].top_p // .["ovos-openai-plugin"].top_p // .solvers["ovos-solver-openai-plugin"].top_p // .solvers["ovos-openai-plugin"].top_p // ""' "$llm_persona_file" 2>>"$LOG_FILE" || true)"
  llm_existing_url="$(normalize_llm_url "$llm_existing_url")"
  llm_existing_max_tokens="$(normalize_llm_positive_int "$llm_existing_max_tokens")"
  llm_existing_temperature="$(normalize_llm_decimal_in_range "$llm_existing_temperature" "0" "2")"
  llm_existing_top_p="$(normalize_llm_decimal_in_range "$llm_existing_top_p" "0" "1")"
fi

if [ -n "$llm_existing_url" ] && [ -n "$llm_existing_key" ] && [ -n "$llm_existing_model" ] && [ -n "$llm_existing_persona" ] && \
  [ -n "$llm_existing_max_tokens" ] && [ -n "$llm_existing_temperature" ] && [ -n "$llm_existing_top_p" ]; then
  _llm_existing_prompt="${LLM_CONTENT_EXISTING//__URL__/$llm_existing_url}"
  _llm_existing_prompt="${_llm_existing_prompt//__MODEL__/$llm_existing_model}"
  if tui_whiptail_dialog --yesno --yes-button "$YES_BUTTON" --no-button "$NO_BUTTON" \
    --title "$LLM_TITLE_EXISTING" "$_llm_existing_prompt" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"; then
    exit_status=0
    export FEATURE_LLM="true"
    export LLM_API_URL="$llm_existing_url"
    LLM_API_KEY="$llm_existing_key"
    export LLM_MODEL="$llm_existing_model"
    export LLM_PERSONA="$llm_existing_persona"
    export LLM_MAX_TOKENS="$llm_existing_max_tokens"
    export LLM_TEMPERATURE="$llm_existing_temperature"
    export LLM_TOP_P="$llm_existing_top_p"
    persist_llm_state
    restore_llm_xtrace
    return
  else
    exit_status=$?
  fi
  if [ "$exit_status" -eq 255 ]; then
    cancel_llm_setup
    return
  fi
fi

tui_whiptail_dialog_allow_escape --msgbox --title "$LLM_TITLE_SETUP" "$LLM_CONTENT_HAVE_DETAILS" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

llm_url_default=""
if [ -n "$llm_existing_url" ]; then
  llm_url_default="$llm_existing_url"
elif [ -f "$INSTALLER_STATE_FILE" ]; then
  llm_url_default="$(normalize_llm_url "$(jq -r '.llm.api_url // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE" || true)")"
fi
if [ -z "$llm_url_default" ]; then
  llm_url_default="${LLM_API_URL:-https://llama.smartgic.io/v1}"
fi

llm_persona_default=""
if [ -n "$llm_existing_persona" ]; then
  llm_persona_default="$llm_existing_persona"
elif [ -f "$INSTALLER_STATE_FILE" ]; then
  llm_persona_default="$(jq -r '.llm.persona // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE" || true)"
  llm_persona_default="$(normalize_llm_persona_default "$llm_persona_default")"
fi
if [ -z "$llm_persona_default" ]; then
  llm_persona_default="${LLM_PERSONA:-$LLM_DEFAULT_PERSONA}"
fi

llm_model_default=""
if [ -n "$llm_existing_model" ]; then
  llm_model_default="$llm_existing_model"
elif [ -f "$INSTALLER_STATE_FILE" ]; then
  llm_model_default="$(jq -r '.llm.model // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE" || true)"
fi
if [ -z "$llm_model_default" ]; then
  llm_model_default="${LLM_MODEL:-gpt-4o-mini}"
fi

llm_max_tokens_default=""
if [ -n "$llm_existing_max_tokens" ]; then
  llm_max_tokens_default="$llm_existing_max_tokens"
elif [ -f "$INSTALLER_STATE_FILE" ]; then
  llm_max_tokens_default="$(normalize_llm_positive_int "$(jq -r '.llm.max_tokens // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE" || true)")"
fi
if [ -z "$llm_max_tokens_default" ]; then
  llm_max_tokens_default="${LLM_MAX_TOKENS:-$LLM_DEFAULT_MAX_TOKENS}"
fi

llm_temperature_default=""
if [ -n "$llm_existing_temperature" ]; then
  llm_temperature_default="$llm_existing_temperature"
elif [ -f "$INSTALLER_STATE_FILE" ]; then
  llm_temperature_default="$(normalize_llm_decimal_in_range "$(jq -r '.llm.temperature // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE" || true)" "0" "2")"
fi
if [ -z "$llm_temperature_default" ]; then
  llm_temperature_default="${LLM_TEMPERATURE:-$LLM_DEFAULT_TEMPERATURE}"
fi

llm_top_p_default=""
if [ -n "$llm_existing_top_p" ]; then
  llm_top_p_default="$llm_existing_top_p"
elif [ -f "$INSTALLER_STATE_FILE" ]; then
  llm_top_p_default="$(normalize_llm_decimal_in_range "$(jq -r '.llm.top_p // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE" || true)" "0" "1")"
fi
if [ -z "$llm_top_p_default" ]; then
  llm_top_p_default="${LLM_TOP_P:-$LLM_DEFAULT_TOP_P}"
fi

while :; do
  llm_url_input=""
  if ! tui_whiptail_capture llm_url_input --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$LLM_TITLE_URL" "$LLM_CONTENT_URL" 25 80 "$llm_url_default"; then
    cancel_llm_setup
    return
  fi

  LLM_API_URL="$(normalize_llm_url "$llm_url_input")"
  if [ -z "$LLM_API_URL" ]; then
    tui_whiptail_dialog_allow_escape --msgbox --title "$LLM_TITLE_INVALID" "$LLM_CONTENT_INVALID_URL" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
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

  if tui_whiptail_capture LLM_API_KEY --passwordbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$LLM_TITLE_KEY" "$_llm_key_prompt" 25 80; then
    exit_status=0
  else
    exit_status=$?
  fi
  if [ "$exit_status" -eq 0 ] && [ -z "$LLM_API_KEY" ] && [ -n "$llm_existing_key" ]; then
    LLM_API_KEY="$llm_existing_key"
  fi
  if [ "$exit_status" -ne 0 ]; then
    cancel_llm_setup
    return
  fi
  if [ -z "$LLM_API_KEY" ]; then
    tui_whiptail_dialog_allow_escape --msgbox --title "$LLM_TITLE_INVALID" "$LLM_CONTENT_MISSING_INFO" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  break
done

while :; do
  if ! tui_whiptail_capture LLM_MODEL --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$LLM_TITLE_MODEL" "$LLM_CONTENT_MODEL" 25 80 "$llm_model_default"; then
    cancel_llm_setup
    return
  fi
  LLM_MODEL="$(trim_llm_input "$LLM_MODEL")"
  if [ -z "$LLM_MODEL" ]; then
    tui_whiptail_dialog_allow_escape --msgbox --title "$LLM_TITLE_INVALID" "$LLM_CONTENT_MISSING_INFO" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  llm_model_default="$LLM_MODEL"
  export LLM_MODEL
  break
done

while :; do
  if ! tui_whiptail_capture LLM_PERSONA --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$LLM_TITLE_PERSONA" "$LLM_CONTENT_PERSONA" 25 80 "$llm_persona_default"; then
    cancel_llm_setup
    return
  fi
  LLM_PERSONA="$(trim_llm_input "$LLM_PERSONA")"
  if [ -z "$LLM_PERSONA" ]; then
    tui_whiptail_dialog_allow_escape --msgbox --title "$LLM_TITLE_INVALID" "$LLM_CONTENT_MISSING_INFO" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  export LLM_PERSONA
  break
done

while :; do
  llm_max_tokens_input=""
  if ! tui_whiptail_capture llm_max_tokens_input --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$LLM_TITLE_MAX_TOKENS" "$LLM_CONTENT_MAX_TOKENS" 25 80 "$llm_max_tokens_default"; then
    cancel_llm_setup
    return
  fi

  LLM_MAX_TOKENS="$(normalize_llm_positive_int "$llm_max_tokens_input")"
  if [ -z "$LLM_MAX_TOKENS" ]; then
    tui_whiptail_dialog_allow_escape --msgbox --title "$LLM_TITLE_INVALID" "$LLM_CONTENT_INVALID_MAX_TOKENS" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  llm_max_tokens_default="$LLM_MAX_TOKENS"
  export LLM_MAX_TOKENS
  break
done

while :; do
  llm_temperature_input=""
  if ! tui_whiptail_capture llm_temperature_input --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$LLM_TITLE_TEMPERATURE" "$LLM_CONTENT_TEMPERATURE" 25 80 "$llm_temperature_default"; then
    cancel_llm_setup
    return
  fi

  LLM_TEMPERATURE="$(normalize_llm_decimal_in_range "$llm_temperature_input" "0" "2")"
  if [ -z "$LLM_TEMPERATURE" ]; then
    tui_whiptail_dialog_allow_escape --msgbox --title "$LLM_TITLE_INVALID" "$LLM_CONTENT_INVALID_TEMPERATURE" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  llm_temperature_default="$LLM_TEMPERATURE"
  export LLM_TEMPERATURE
  break
done

while :; do
  llm_top_p_input=""
  if ! tui_whiptail_capture llm_top_p_input --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" \
    --title "$LLM_TITLE_TOP_P" "$LLM_CONTENT_TOP_P" 25 80 "$llm_top_p_default"; then
    cancel_llm_setup
    return
  fi

  LLM_TOP_P="$(normalize_llm_decimal_in_range "$llm_top_p_input" "0" "1")"
  if [ -z "$LLM_TOP_P" ]; then
    tui_whiptail_dialog_allow_escape --msgbox --title "$LLM_TITLE_INVALID" "$LLM_CONTENT_INVALID_TOP_P" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"
    continue
  fi

  llm_top_p_default="$LLM_TOP_P"
  export LLM_TOP_P
  break
done

export FEATURE_LLM="true"
persist_llm_state
restore_llm_xtrace

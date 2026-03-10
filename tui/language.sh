#!/usr/bin/env bash
# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh
message="
Please select a language:
"

active_language="English"
available_languages=(Basque Catalan Dutch English French Galician German Hindi Italian Portuguese Spanish)

whiptail_args=(
  --title "Open Voice OS Installation - Language"
  --radiolist "$message"
  --cancel-button "Exit"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "${#available_languages[@]}"
)

for language in "${available_languages[@]}"; do
  whiptail_args+=("$language" "")
  if [[ $language = "$active_language" ]]; then
    whiptail_args+=("ON")
  else
    whiptail_args+=("OFF")
  fi
done

# Retrieve language and make it lower case with ",,"
if ! tui_whiptail_capture language "${whiptail_args[@]}"; then
  language=""
fi
language="${language,,}"

if [ -z "$language" ]; then
  exit 0
fi

# Hash of locales
declare -A locales
locales=(["catalan"]="ca-es" ["english"]="en-us" ["french"]="fr-fr" ["galician"]="gl-es" ["german"]="de-de" ["hindi"]="hi-in" ["italian"]="it-it" ["spanish"]="es-es" ["dutch"]="nl-nl" ["portuguese"]="pt-pt" ["basque"]="eu-es")
export LOCALE="${locales[$language]}"

#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh
message="
Please select a language:
"

active_language="English"
available_languages=(Basque Catalan Dutch English French Galician German Hindi Italian Kabyle Portuguese Spanish)

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

# This is the first screen of the installer, and the one every other screen
# eventually goes back to, so its cancel button is the way out of the whole
# run. Confirm it: a user who reaches it from the far end of the flow has a
# screenful of answers to lose.
while :; do
  # Retrieve language and make it lower case with ",,"
  if ! tui_whiptail_capture language "${whiptail_args[@]}"; then
    language=""
  fi
  language="${language,,}"

  if [ -n "$language" ]; then
    break
  fi

  if tui_nav_confirm_quit; then
    tui_nav_quit
  fi
done

# Hash of locales
declare -A locales
locales=(["basque"]="eu-es" ["catalan"]="ca-es" ["dutch"]="nl-nl" ["english"]="en-us" ["french"]="fr-fr" ["galician"]="gl-es" ["german"]="de-de" ["hindi"]="hi-in" ["italian"]="it-it" ["kabyle"]="kab-dz" ["portuguese"]="pt-pt" ["spanish"]="es-es")
export LOCALE="${locales[$language]}"

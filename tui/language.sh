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
# eventually goes back to, so its cancel button is the way out of the whole run.
#
# Only the cancel button is a decision. Everything else that leaves the picker
# unanswered - a terminal too small to draw it, a TERM whiptail does not know,
# a newt that reports ESC as an error - is a failure, and failures are retried
# a bounded number of times and then reported as what they are. Pressing Exit
# and changing your mind is a human loop, not a failure, and is never counted.
language_failures=0

while :; do
  language_status=0
  # Retrieve language and make it lower case with ",,"
  tui_whiptail_capture language "${whiptail_args[@]}" || language_status=$?
  if [ "$language_status" -ne 0 ]; then
    language=""
  fi
  language="${language,,}"

  if [ -n "$language" ]; then
    break
  fi

  if [ "$language_status" -eq 1 ]; then
    language_failures=0

    # On the first pass nothing has been answered yet, so leaving costs the
    # user nothing and a confirmation would only be in the way. Arriving here
    # from the far end of the flow is different: that is a screenful of
    # answers to lose.
    if [ "${TUI_LANGUAGE_REVISITED:-false}" != "true" ]; then
      tui_nav_quit
    fi

    if tui_nav_confirm_quit; then
      tui_nav_quit
    fi
    continue
  fi

  # A terminal that cannot draw the picker cannot draw a prompt about it
  # either, so after the retries are spent this leaves with an error - not
  # with a claim that the user cancelled, and not with a success status.
  language_failures=$((language_failures + 1))
  if [ "$language_failures" -ge 3 ]; then
    printf '%s\n' "The language screen could not be drawn or was dismissed repeatedly." >&2
    printf '%s\n' "If no dialog appeared, check the terminal size and the TERM setting." >&2
    exit "${EXIT_FAILURE:-1}"
  fi
done

# Hash of locales
declare -A locales
locales=(["basque"]="eu-es" ["catalan"]="ca-es" ["dutch"]="nl-nl" ["english"]="en-us" ["french"]="fr-fr" ["galician"]="gl-es" ["german"]="de-de" ["hindi"]="hi-in" ["italian"]="it-it" ["kabyle"]="kab-dz" ["portuguese"]="pt-pt" ["spanish"]="es-es")
export LOCALE="${locales[$language]}"

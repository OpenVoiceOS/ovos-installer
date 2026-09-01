#!/usr/bin/env bash
# Navigation shared by every screen of the installer TUI.
#
# Screens do not chain into each other. Each one reports what the user asked
# for through TUI_NAV and returns, and tui/main.sh walks the flow:
#
#   next    continue with the following screen (the default)
#   back    return to the previous screen the user actually saw
#   repeat  render the same screen again
#
# Leaving the installer is a button, not a key. whiptail puts the terminal in
# raw mode so Ctrl-C never reaches the installer, and ESC has not been a newt
# form hotkey since 0.52.5 (Debian #584098), so neither can be relied on. Going
# back from the first screen reaches the language picker, whose own cancel
# button leaves, and that path works on every terminal.

# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh

TUI_NAV="${TUI_NAV:-next}"
export TUI_NAV

# The order every screen is visited in. Steps that do not apply to the current
# run are stepped over in both directions, so "back" always lands on the
# previous screen the user actually saw.
declare -a TUI_FLOW=(
  welcome
  hardware_confirmation
  detection
  methods
  channels
  profiles
  features
  satellite
  tuning
  summary
  telemetry
  usage_telemetry
)

# Load the shared button labels. English first, so a locale that has not been
# translated yet still has every string, then the selected locale on top.
function tui_nav_load_strings() {
  # shellcheck source=tui/locales/en-us/misc.sh
  source tui/locales/en-us/misc.sh

  local locale_file="tui/locales/${LOCALE:-en-us}/misc.sh"
  if [ "$locale_file" != "tui/locales/en-us/misc.sh" ] && [ -f "$locale_file" ]; then
    # shellcheck source=tui/locales/en-us/misc.sh
    source "$locale_file"
  fi

  # Keep the navigation hint on screen at every step. Nothing else tells a user
  # over SSH that the cancel button is how they go back, and how they get out.
  # It gets the whole line: every dialog title already names the installer, and
  # a hint clipped by an 80 column terminal is the one that stops being read.
  TUI_BACKTITLE="${NAV_HINT:-}"
  export TUI_BACKTITLE
}

# The size the dialogs will actually be drawn at. Screens that lay text out
# themselves, rather than handing it to whiptail to wrap, have to measure
# against this and not against the preferred size.
function tui_nav_fit_window() {
  local fitted=""

  fitted="$(tui_whiptail_fit "${TUI_WINDOW_HEIGHT:-35}" "${TUI_WINDOW_WIDTH:-90}")" || true
  TUI_EFFECTIVE_HEIGHT="${fitted%% *}"
  TUI_EFFECTIVE_WIDTH="${fitted##* }"
  export TUI_EFFECTIVE_HEIGHT TUI_EFFECTIVE_WIDTH
}

tui_nav_load_strings
tui_nav_fit_window

function tui_nav_set() {
  TUI_NAV="$1"
  export TUI_NAV
}

function tui_nav_reset() {
  tui_nav_set "next"
}

# Leave the installer. The TUI runs entirely before the Ansible playbook, so
# there is nothing to roll back at this point.
function tui_nav_quit() {
  if declare -F log_info >/dev/null 2>&1; then
    log_info ""
    log_info "➤ Installation cancelled, nothing has been changed."
  fi

  exit "${EXIT_SUCCESS:-0}"
}

# Nothing is lost by quitting, but a run does carry a screenful of answers, so
# ask before throwing them away.
function tui_nav_confirm_quit() {
  local status=0

  tui_nav_load_strings
  tui_whiptail_dialog --yesno --defaultno \
    --yes-button "${QUIT_BUTTON:-Quit}" --no-button "${BACK_BUTTON:-Back}" \
    --title "${QUIT_TITLE:-Open Voice OS Installation - Quit}" \
    "${QUIT_CONTENT:-Do you really want to quit the installer?}" \
    "${TUI_WINDOW_HEIGHT:-35}" "${TUI_WINDOW_WIDTH:-90}" || status=$?

  [ "$status" -eq 0 ]
}

# Turn a whiptail exit status into a navigation action.
#   0  the user confirmed the screen
#   1  the user pressed the cancel button, which every screen labels "Back"
# Anything else is whiptail failing to render, and the screens have always
# treated that as a cancel rather than pushing the user forward blindly.
function tui_nav_from_status() {
  if [ "${1:-0}" -eq 0 ]; then
    tui_nav_set "next"
    return 0
  fi

  tui_nav_set "back"
}

# Screen-facing wrappers. They return success only when the flow should carry
# on, so a screen reads as `if ! tui_nav_capture ...; then return 0; fi`.
function tui_nav_capture() {
  local status=0

  tui_whiptail_capture "$@" || status=$?
  tui_nav_from_status "$status"

  [ "$TUI_NAV" == "next" ]
}

function tui_nav_dialog() {
  local status=0

  tui_whiptail_dialog "$@" || status=$?
  tui_nav_from_status "$status"

  [ "$TUI_NAV" == "next" ]
}

# Which steps this particular run goes through.
function tui_flow_step_enabled() {
  case "$1" in
    features)
      [[ "${PROFILE:-}" != "satellite" ]]
      ;;
    satellite)
      [[ "${PROFILE:-}" == "satellite" ]]
      ;;
    tuning)
      [[ "${RASPBERRYPI_MODEL:-N/A}" != "N/A" ]]
      ;;
    telemetry | usage_telemetry)
      [[ "${EXISTING_INSTANCE:-false}" != "true" ]]
      ;;
    *)
      return 0
      ;;
  esac
}

# The hardware confirmation asks its question once and remembers the answer, so
# walking back into it would bounce the user straight forward again. It is only
# ever entered going forward.
function tui_flow_step_is_backward_transparent() {
  [ "$1" == "hardware_confirmation" ]
}

# Index of the next step to run, or ${#TUI_FLOW[@]} when the flow is over.
function tui_flow_next_index() {
  local index=$(( ${1:-0} + 1 ))

  while [ "$index" -lt "${#TUI_FLOW[@]}" ] && ! tui_flow_step_enabled "${TUI_FLOW[$index]}"; do
    index=$((index + 1))
  done

  printf '%s' "$index"
}

# Index of the previous step to run, or -1 when there is nothing before it.
function tui_flow_previous_index() {
  local index=$(( ${1:-0} - 1 ))
  local step=""

  while [ "$index" -ge 0 ]; do
    step="${TUI_FLOW[$index]}"
    if tui_flow_step_enabled "$step" && ! tui_flow_step_is_backward_transparent "$step"; then
      break
    fi
    index=$((index - 1))
  done

  printf '%s' "$index"
}

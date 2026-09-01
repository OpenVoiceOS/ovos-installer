#!/usr/bin/env bash

# Smallest box worth drawing. Below this whiptail has no room for a title, a
# line of text and a button row, and the screen is unusable either way.
TUI_WINDOW_MIN_HEIGHT="10"
TUI_WINDOW_MIN_WIDTH="40"

# Rows and columns of the terminal the installer is attached to, as
# "<lines> <columns>". Fails when there is no controlling terminal, which is
# how the tests and any non-interactive run keep the preferred size.
function tui_terminal_size() {
  local size=""

  # The group takes the redirection too: without a controlling terminal it is
  # bash, not stty, that reports "/dev/tty: No such device or address".
  if size="$({ stty size <"${TUI_TTY:-/dev/tty}"; } 2>/dev/null)" &&
    [[ "$size" =~ ^[0-9]+\ [0-9]+$ ]]; then
    printf '%s' "$size"
    return 0
  fi

  return 1
}

# whiptail draws the box at whatever size it is handed and pushes the buttons
# off screen when that does not fit. The preferred size is 35x90, so on an
# 80x24 SSH window - the most ordinary terminal there is - every screen came
# out with no way to answer it. Treat the preferred size as a maximum and fit
# the rest to the terminal.
#
# Echoes "<height> <width>", and returns 1 when the box had to be shrunk so the
# caller knows the body may no longer fit.
function tui_whiptail_fit() {
  local height="$1"
  local width="$2"
  local size=""
  local lines=""
  local columns=""
  local fitted_height="$height"
  local fitted_width="$width"

  if size="$(tui_terminal_size)"; then
    lines="${size%% *}"
    columns="${size##* }"

    # One row for the backtitle, which newt draws above the box, and one for the
    # drop shadow below it. Ask for more and newt has nowhere to put the box.
    if [ "$fitted_height" -gt "$((lines - 2))" ]; then
      fitted_height="$((lines - 2))"
    fi
    # Two columns for the drop shadow whiptail draws to the right of the box.
    # Anything more is width the body could have wrapped into.
    if [ "$fitted_width" -gt "$((columns - 2))" ]; then
      fitted_width="$((columns - 2))"
    fi
  fi

  if [ "$fitted_height" -lt "$TUI_WINDOW_MIN_HEIGHT" ]; then
    fitted_height="$TUI_WINDOW_MIN_HEIGHT"
  fi
  if [ "$fitted_width" -lt "$TUI_WINDOW_MIN_WIDTH" ]; then
    fitted_width="$TUI_WINDOW_MIN_WIDTH"
  fi

  printf '%s %s' "$fitted_height" "$fitted_width"

  [ "$fitted_height" -eq "$height" ] && [ "$fitted_width" -eq "$width" ]
}

# Options whiptail takes a value for. Everything else that starts with a dash
# is a flag, and what is left over are the positional arguments: whiptail uses
# popt, so the box option does not have to come before them and in this code
# base usually does not.
# Not readonly: every screen sources this file, so it is declared many times.
declare -a TUI_WHIPTAIL_VALUE_OPTIONS=(
  --backtitle
  --cancel-button
  --default-item
  --no-button
  --ok-button
  --output-fd
  --title
  --yes-button
)

function tui_whiptail_is_value_option() {
  local candidate="$1"
  local option=""

  for option in "${TUI_WHIPTAIL_VALUE_OPTIONS[@]}"; do
    if [ "$candidate" == "$option" ]; then
      return 0
    fi
  done

  return 1
}

# Every box option lays its operands out as "<text|file> <height> <width>", and
# the list boxes follow it with "<list height>". Echoes the indices of those
# four as "<text> <height> <width> <list height>", with -1 for a box that has
# no list, or nothing when the call does not look like a box. The indices are
# not adjacent: flags sit between them.
function tui_whiptail_size_indices() {
  local -n arguments="$1"
  local index=0
  local -a positional=()

  for ((index = 0; index < ${#arguments[@]}; index++)); do
    if tui_whiptail_is_value_option "${arguments[$index]}"; then
      index=$((index + 1))
      continue
    fi

    case "${arguments[$index]}" in
      -*) continue ;;
    esac

    positional+=("$index")
  done

  if [ "${#positional[@]}" -lt 3 ]; then
    return 1
  fi

  if ! [[ "${arguments[${positional[1]}]}" =~ ^[0-9]+$ ]] ||
    ! [[ "${arguments[${positional[2]}]}" =~ ^[0-9]+$ ]]; then
    return 1
  fi

  local list_height_index="-1"
  case " ${arguments[*]} " in
    *" --menu "* | *" --checklist "* | *" --radiolist "*)
      if [ "${#positional[@]}" -ge 4 ] &&
        [[ "${arguments[${positional[3]}]}" =~ ^[0-9]+$ ]]; then
        list_height_index="${positional[3]}"
      fi
      ;;
  esac

  local options=0
  if [ "$list_height_index" -ge 0 ]; then
    options=$(( (${#positional[@]} - 4) / 3 ))
  fi

  printf '%s %s %s %s %s' \
    "${positional[0]}" "${positional[1]}" "${positional[2]}" "$list_height_index" "$options"
}

# The locale templates end every body with a blank line. whiptail anchors the
# buttons to the bottom of the box, so those rows buy nothing and only push the
# text towards a scrollbar on a small terminal. The blank line at the top is
# left alone: that one is the padding between the border and the first line.
function tui_whiptail_trim_body() {
  local text="$1"
  local line=""

  while [ -n "$text" ]; do
    line="${text##*$'\n'}"
    if [ "$line" == "$text" ] || [ -n "${line//[[:space:]]/}" ]; then
      break
    fi
    text="${text%$'\n'*}"
  done

  printf '%s' "$text"
}

# whiptail gives the body every row of the box but six - two for the border, two
# for the padding around the text and two for the button row - and a list box
# takes its own rows on top of that. Wrap the text the way it will be drawn and
# say whether it runs past what is left.
function tui_whiptail_body_overflows() {
  local text="$1"
  local height="$2"
  local width="$3"
  local list_height="${4:-0}"
  local available="$((height - 6 - list_height))"
  local wrap="$((width - 4))"
  local rows=0

  if [ "$available" -lt 1 ] || [ "$wrap" -lt 1 ]; then
    return 1
  fi

  rows="$(printf '%s\n' "$text" | fold -s -w "$wrap" | wc -l)"

  [ "$rows" -gt "$available" ]
}

# Every dialog carries the same backtitle, so the navigation keys stay on
# screen whichever step the user is on, and every dialog is fitted to the
# terminal. TUI_BACKTITLE is set by tui/navigation.sh.
function tui_whiptail_run() {
  local -a args=("$@")
  local indices=""
  local -a size_index=()
  local text_index=""
  local height_index=""
  local width_index=""
  local list_height_index="-1"
  local list_height="0"
  local options="0"
  local fitted=""

  if indices="$(tui_whiptail_size_indices args)"; then
    read -r -a size_index <<<"$indices"
    text_index="${size_index[0]}"
    height_index="${size_index[1]}"
    width_index="${size_index[2]}"
    list_height_index="${size_index[3]}"
    options="${size_index[4]}"
    if [ "$list_height_index" -ge 0 ]; then
      list_height="${args[$list_height_index]}"
    fi

    # --textbox takes a file name here, not text to lay out.
    case " ${args[*]} " in
      *" --textbox "* | *" --gauge "*) ;;
      *) args[text_index]="$(tui_whiptail_trim_body "${args[$text_index]}")" ;;
    esac

    fitted="$(tui_whiptail_fit "${args[$height_index]}" "${args[$width_index]}")" || true
    args[height_index]="${fitted%% *}"
    args[width_index]="${fitted##* }"

    # The screens ask for a list four rows tall even when they offer two
    # options, which looks fine with room to spare and wastes rows there is no
    # room for. Give the spare rows back to the body rather than to blank list
    # entries, but only when the body needs them.
    if [ "$list_height_index" -ge 0 ] && [ "$options" -ge 1 ] &&
      [ "$list_height" -gt "$options" ] &&
      tui_whiptail_body_overflows "${args[$text_index]}" \
        "${args[$height_index]}" "${args[$width_index]}" "$list_height"; then
      args[list_height_index]="$options"
      list_height="$options"
    fi

    # Only give the body a scrollbar when it genuinely does not fit. It costs
    # the user a Tab to reach the buttons, because whiptail puts the focus in
    # the scrollable region, so it is worth it only when the alternative is
    # text they cannot see at all.
    if tui_whiptail_body_overflows "${args[$text_index]}" \
      "${args[$height_index]}" "${args[$width_index]}" "$list_height"; then
      case " ${args[*]} " in
        *" --textbox "* | *" --gauge "* | *" --infobox "*) ;;
        *) args=(--scrolltext "${args[@]}") ;;
      esac
    fi
  fi

  if [ -n "${TUI_BACKTITLE:-}" ]; then
    whiptail --backtitle "$TUI_BACKTITLE" "${args[@]}"
  else
    whiptail "${args[@]}"
  fi
}

# Run whiptail without letting expected dialog statuses trip errexit.
function tui_whiptail_dialog() {
  local had_errexit="false"
  local status

  case "$-" in
    *e*)
      had_errexit="true"
      set +e
      ;;
  esac

  tui_whiptail_run "$@"
  status=$?

  if [ "$had_errexit" == "true" ]; then
    set -e
  fi

  return "$status"
}

# Run whiptail and treat ESC/cancel as non-fatal for informational dialogs.
function tui_whiptail_dialog_allow_escape() {
  local had_errexit="false"
  local status

  case "$-" in
    *e*)
      had_errexit="true"
      set +e
      ;;
  esac

  tui_whiptail_run "$@"
  status=$?

  if [ "$had_errexit" == "true" ]; then
    set -e
  fi

  if [ "$status" -eq 255 ]; then
    return 0
  fi

  return "$status"
}

# Capture whiptail output while preserving its exit status under errexit.
function tui_whiptail_capture() {
  if [ "$#" -lt 1 ]; then
    printf '%s\n' "tui_whiptail_capture: missing output variable" >&2
    return 2
  fi

  local output_var="$1"
  shift

  local had_errexit="false"
  local output=""
  local status

  case "$-" in
    *e*)
      had_errexit="true"
      set +e
      ;;
  esac

  output="$(tui_whiptail_run "$@" 3>&1 1>&2 2>&3)"
  status=$?

  if [ "$had_errexit" == "true" ]; then
    set -e
  fi

  printf -v "$output_var" '%s' "$output"
  return "$status"
}

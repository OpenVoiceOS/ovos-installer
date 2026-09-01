#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh
# The locked description interpolates INSTANCE_TYPE, which detect_existing_instance
# leaves unset when it finds nothing. Sourcing a locale under nounset would abort
# the installer there, so give it a value before any locale is read.
export INSTANCE_TYPE="${INSTANCE_TYPE:-}"

# Load English first so a locale that is missing, or not translated yet, still
# has every string defined, then let the selected locale override what it has.
# shellcheck source=tui/locales/en-us/methods.sh
source tui/locales/en-us/methods.sh
_methods_locale_file="tui/locales/$LOCALE/methods.sh"
if [ "$_methods_locale_file" != "tui/locales/en-us/methods.sh" ] && [ -f "$_methods_locale_file" ]; then
  # shellcheck source=tui/locales/en-us/methods.sh
  source "$_methods_locale_file"
fi
# shellcheck source=tui/hardware_state.sh
source tui/hardware_state.sh

declare -a available_methods
active_method="virtualenv"
available_methods=(containers virtualenv)

# Containers are not supported in the macOS TUI flow.
if [[ "${DISTRO_NAME:-}" == "macos" ]]; then
  active_method="virtualenv"
  available_methods=(virtualenv)
fi

# When 32-bit CPU is detected, the only method available
# will be Python virtualenv as there are no 32-bit container
# images available. Same for Raspberry Pi 3 as containers
# might be too heavy for this board.
if { [[ "$ARCH" != "x86_64" && "$ARCH" != "aarch64" ]] || [[ "$RASPBERRYPI_MODEL" == *"Raspberry Pi 3"* ]]; }; then
  active_method="virtualenv"
  available_methods=(virtualenv)
fi

# Limit available method to match the existing instance
# If containers instance has been deployed then only containers
# method will be available.
if [ "$EXISTING_INSTANCE" == "true" ]; then
  case "${INSTANCE_TYPE:-}" in
    virtualenv)
      active_method="$INSTANCE_TYPE"
      available_methods=("$INSTANCE_TYPE")
      ;;
    containers)
      if [[ "${DISTRO_NAME:-}" != "macos" ]]; then
        active_method="$INSTANCE_TYPE"
        available_methods=("$INSTANCE_TYPE")
      fi
      ;;
  esac
fi

# Mark 2/DevKit devices only support virtualenv installs.
if [[ "$TUI_MARK2_OR_DEVKIT_DETECTED" == "true" ]]; then
  active_method="virtualenv"
  available_methods=(virtualenv)
fi

# When an existing instance pins the method, the radiolist would otherwise show
# a single entry under a description of a choice the user no longer has. Say why
# the list is limited and how to change it.
if [ "$EXISTING_INSTANCE" == "true" ] &&
  [ "${#available_methods[@]}" -eq 1 ] &&
  [ "${available_methods[0]}" == "${INSTANCE_TYPE:-}" ]; then
  if [ -n "${LOCKED_CONTENT:-}" ]; then
    CONTENT="$LOCKED_CONTENT"
  fi
fi

list_height="${#available_methods[@]}"
if [ "$list_height" -lt 1 ]; then
  available_methods=(virtualenv)
  active_method="virtualenv"
  list_height="${#available_methods[@]}"
fi
if [ "$list_height" -lt 4 ]; then
  list_height=4
fi

whiptail_args=(
  --title "$TITLE"
  --radiolist "$CONTENT"
  --cancel-button "$BACK_BUTTON"
  --ok-button "$OK_BUTTON"
  "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH" "$list_height"
)

for method in "${available_methods[@]}"; do
  whiptail_args+=("$method" "")
  if [[ $method = "$active_method" ]]; then
    whiptail_args+=("ON")
  else
    whiptail_args+=("OFF")
  fi
done

if ! tui_nav_capture METHOD "${whiptail_args[@]}"; then
  # The capture emptied METHOD; keep the default this screen would offer again
  # so nothing downstream sees a blank method while the user navigates.
  METHOD="$active_method"
  export METHOD
  return 0
fi
export METHOD

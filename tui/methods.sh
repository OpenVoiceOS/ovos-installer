#!/usr/bin/env bash
# shellcheck source=tui/locales/en-us/methods.sh
source "tui/locales/$LOCALE/methods.sh"

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

METHOD=$(whiptail "${whiptail_args[@]}" 3>&1 1>&2 2>&3)
export METHOD

if [ -z "$METHOD" ]; then
  source tui/detection.sh
  source tui/methods.sh
  return
fi

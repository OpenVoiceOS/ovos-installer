#!/usr/bin/env bash
# shellcheck source=utils/common.sh
source "utils/common.sh"

# Detection locale files build a full CONTENT string when sourced. Seed any
# unset detection variables so the hardware confirmation prompt can reuse their
# localized strings without tripping set -u in reduced test environments.
DISTRO_LABEL="${DISTRO_LABEL:-${DISTRO_NAME:-N/A}}"
KERNEL="${KERNEL:-N/A}"
RASPBERRYPI_MODEL="${RASPBERRYPI_MODEL:-N/A}"
PYTHON="${PYTHON:-N/A}"
CPU_IS_CAPABLE="${CPU_IS_CAPABLE:-N/A}"
HARDWARE_DETECTED="${HARDWARE_DETECTED:-N/A}"
VENV_PATH="${VENV_PATH:-N/A}"
SOUND_SERVER="${SOUND_SERVER:-N/A}"
DISPLAY_SERVER="${DISPLAY_SERVER:-N/A}"
DISPLAY_DETECTED="${DISPLAY_DETECTED:-${DISPLAY_SERVER:-N/A}}"
# shellcheck source=tui/locales/en-us/detection.sh
source "tui/locales/$LOCALE/detection.sh"

function hardware_confirmation_has_detected_device() {
  local needle="$1"
  local device=""

  for device in "${DETECTED_DEVICES[@]:-}"; do
    if [ "$device" = "$needle" ]; then
      return 0
    fi
  done

  return 1
}

function hardware_confirmation_mark2_candidate() {
  if [[ "${RASPBERRYPI_MODEL:-}" == *"Raspberry Pi 4"* ]] && \
    hardware_confirmation_has_detected_device "tas5806"; then
    if hardware_confirmation_has_detected_device "attiny1614"; then
      printf '%s\n' "devkit"
    else
      printf '%s\n' "mark2"
    fi
  fi
}

function hardware_confirmation_strip_mark2_family_devices() {
  local device=""
  local -a filtered_devices=()

  for device in "${DETECTED_DEVICES[@]:-}"; do
    case "$device" in
      tas5806|attiny1614) ;;
      *)
        filtered_devices+=("$device")
        ;;
    esac
  done

  DETECTED_DEVICES=("${filtered_devices[@]}")
}

function hardware_confirmation_add_device() {
  local needle="$1"

  if ! hardware_confirmation_has_detected_device "$needle"; then
    DETECTED_DEVICES+=("$needle")
  fi
}

function hardware_confirmation_apply_choice() {
  local choice="$1"

  hardware_confirmation_strip_mark2_family_devices

  case "$choice" in
    mark2)
      hardware_confirmation_add_device "tas5806"
      ;;
    devkit)
      hardware_confirmation_add_device "tas5806"
      hardware_confirmation_add_device "attiny1614"
      ;;
  esac
}

function hardware_confirmation_persist_state() {
  local choice="$1"
  local state_tmp=""
  local i2c_devices_json="[]"
  local detected_device=""
  local -a detected_devices_to_store=()

  if ! command -v jq &>>"$LOG_FILE"; then
    return 0
  fi

  for detected_device in atmega328p attiny1614 tas5806; do
    if hardware_confirmation_has_detected_device "$detected_device"; then
      detected_devices_to_store+=("$detected_device")
    fi
  done

  if [ "${#detected_devices_to_store[@]}" -gt 0 ]; then
    i2c_devices_json="$(jq -c -n '$ARGS.positional' --args "${detected_devices_to_store[@]}" 2>>"$LOG_FILE" || echo "[]")"
  fi

  if ! state_tmp="$(mktemp "${TMPDIR:-/tmp}/ovos-installer-state.XXXXXX" 2>>"$LOG_FILE")"; then
    return 0
  fi

  if [ -f "$INSTALLER_STATE_FILE" ] && \
    jq --arg hardware_confirmation "$choice" --argjson i2c_devices "$i2c_devices_json" \
      'if type=="object" then . else {} end
       | .hardware_confirmation = $hardware_confirmation
       | .i2c_devices = $i2c_devices' \
      "$INSTALLER_STATE_FILE" >"$state_tmp" 2>>"$LOG_FILE"; then
    mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
  elif jq -n --arg hardware_confirmation "$choice" --argjson i2c_devices "$i2c_devices_json" \
    '{hardware_confirmation: $hardware_confirmation, i2c_devices: $i2c_devices}' \
    >"$state_tmp" 2>>"$LOG_FILE"; then
    mv -f "$state_tmp" "$INSTALLER_STATE_FILE"
  else
    rm -f "$state_tmp"
  fi

  if [ -n "${RUN_AS:-}" ] && [ -f "$INSTALLER_STATE_FILE" ]; then
    chown "$RUN_AS":"$(id -ng "$RUN_AS" 2>>"$LOG_FILE")" "$INSTALLER_STATE_FILE" &>>"$LOG_FILE" || true
  fi
}

hardware_confirmation_choice=""
hardware_confirmation_candidate=""

if [ -f "$INSTALLER_STATE_FILE" ]; then
  hardware_confirmation_choice="$(jq -r '.hardware_confirmation // ""' "$INSTALLER_STATE_FILE" 2>>"$LOG_FILE" || true)"
  case "$hardware_confirmation_choice" in
    mark2|devkit|generic) ;;
    *)
      hardware_confirmation_choice=""
      ;;
  esac
fi

if [[ "${RASPBERRYPI_MODEL:-}" == *"Raspberry Pi 4"* ]]; then
  hardware_confirmation_candidate="$(hardware_confirmation_mark2_candidate)"
fi

if [ -n "$hardware_confirmation_choice" ] && [[ "${RASPBERRYPI_MODEL:-}" == *"Raspberry Pi 4"* ]]; then
  hardware_confirmation_apply_choice "$hardware_confirmation_choice"
elif [ -n "$hardware_confirmation_candidate" ]; then
  : "${HARDWARE_CONFIRMATION_TITLE:=Open Voice OS Installation - Hardware Check}"
  : "${HARDWARE_CONFIRMATION_MARK2_CONTENT:=A Raspberry Pi 4 with a TAS5806 audio device was detected.\n\nThis can be a Mycroft Mark II, but some generic HATs expose the same signal.\n\nIs this device actually a Mycroft Mark II?}"
  : "${HARDWARE_CONFIRMATION_DEVKIT_CONTENT:=A Raspberry Pi 4 with TAS5806 and attiny1614 devices was detected.\n\nThis can be a Mycroft DevKit, but some generic HATs expose the same signal.\n\nIs this device actually a Mycroft DevKit?}"
  : "${HARDWARE_CONFIRMATION_GENERIC_NOTE:=Choose No to continue with the generic Raspberry Pi flow.}"

  if [ "$hardware_confirmation_candidate" = "devkit" ]; then
    hardware_confirmation_content="${HARDWARE_CONFIRMATION_DEVKIT_CONTENT}\n\n${HARDWARE_CONFIRMATION_GENERIC_NOTE}"
  else
    hardware_confirmation_content="${HARDWARE_CONFIRMATION_MARK2_CONTENT}\n\n${HARDWARE_CONFIRMATION_GENERIC_NOTE}"
  fi

  if whiptail --yes-button "$YES_BUTTON" --no-button "$NO_BUTTON" \
    --title "$HARDWARE_CONFIRMATION_TITLE" \
    --yesno "$hardware_confirmation_content" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"; then
    hardware_confirmation_choice="$hardware_confirmation_candidate"
  else
    hardware_confirmation_choice="generic"
  fi

  hardware_confirmation_apply_choice "$hardware_confirmation_choice"
fi

if [ -n "$hardware_confirmation_choice" ]; then
  export HARDWARE_CONFIRMATION="$hardware_confirmation_choice"
  hardware_confirmation_persist_state "$hardware_confirmation_choice"
fi

enforce_mark2_devkit_trixie_requirement
enforce_mark2_alpha_channel
enforce_mark2_devkit_gui_support
enforce_mark2_devkit_display_server

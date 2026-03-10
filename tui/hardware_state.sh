#!/usr/bin/env bash
# Centralize TUI-side hardware classification so every screen uses the same
# Mark 1 / Mark II / DevKit interpretation of the current detection state.

function tui_hardware_has_detected_device() {
    local needle="$1"
    local device=""

    for device in "${DETECTED_DEVICES[@]:-}"; do
        if [ "$device" = "$needle" ]; then
            return 0
        fi
    done

    return 1
}

function tui_is_raspberry_pi_4() {
    [[ "${RASPBERRYPI_MODEL:-}" =~ (^|[[:space:]])Raspberry[[:space:]]Pi[[:space:]]4([^0-9]|$) ]]
}

TUI_MARK2_OR_DEVKIT_DETECTED="false"
TUI_DEVKIT_DETECTED="false"
TUI_HARDWARE_DETECTED="N/A"

if tui_hardware_has_detected_device "atmega328p"; then
    TUI_HARDWARE_DETECTED="Mycroft Mark 1"
fi

if tui_is_raspberry_pi_4 && tui_hardware_has_detected_device "tas5806"; then
    TUI_MARK2_OR_DEVKIT_DETECTED="true"
    if tui_hardware_has_detected_device "attiny1614"; then
        TUI_DEVKIT_DETECTED="true"
        TUI_HARDWARE_DETECTED="Mycroft DevKit"
    else
        TUI_HARDWARE_DETECTED="Mycroft Mark II"
    fi
fi

if [ "$TUI_HARDWARE_DETECTED" = "N/A" ] && [ -n "${HARDWARE_MODEL:-}" ] && [ "$HARDWARE_MODEL" != "N/A" ]; then
    TUI_HARDWARE_DETECTED="$HARDWARE_MODEL"
fi

export TUI_MARK2_OR_DEVKIT_DETECTED TUI_DEVKIT_DETECTED TUI_HARDWARE_DETECTED

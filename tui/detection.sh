#!/bin/env bash

HARDWARE_DETECTED="N/A"

for device in "${DETECTED_DEVICES[@]}"; do
    case ${device} in
    tas5806)
        HARDWARE_DETECTED="Mycroft Mark II"
        ;;
    atmega328p)
        HARDWARE_DETECTED="Mycroft Mark 1"
        ;;
    attiny1614)
        HARDWARE_DETECTED="Mycroft DevKit"
        ;;        
    esac
done
export HARDWARE_DETECTED

# shellcheck source=locales/en-us/detection.sh
source "tui/locales/$LOCALE/detection.sh"

whiptail --msgbox --ok-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

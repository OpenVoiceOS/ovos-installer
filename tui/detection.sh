#!/usr/bin/env bash
# shellcheck source=tui/hardware_state.sh
source tui/hardware_state.sh

HARDWARE_DETECTED="$TUI_HARDWARE_DETECTED"
export HARDWARE_DETECTED

DISPLAY_DETECTED="${DISPLAY_SERVER^}"
if [ "${DISPLAY_SERVER,,}" == "eglfs" ]; then
    DISPLAY_DETECTED="${DISPLAY_SERVER^^}"
elif [ "${DISPLAY_SERVER:-N/A}" == "N/A" ] && \
    { [ "$HARDWARE_DETECTED" == "Mycroft Mark II" ] || [ "$HARDWARE_DETECTED" == "Mycroft DevKit" ]; }; then
    DISPLAY_DETECTED="EGLFS"
fi
export DISPLAY_DETECTED

# Keep locale templates simple by exposing a single display-ready OS label.
if [ -z "${DISTRO_LABEL:-}" ]; then
    if [ -n "${DISTRO_VERSION:-}" ]; then
        DISTRO_LABEL="${DISTRO_NAME^} ${DISTRO_VERSION}"
    else
        DISTRO_LABEL="${DISTRO_NAME^}"
    fi
fi
export DISTRO_LABEL

# shellcheck source=tui/locales/en-us/detection.sh
source "tui/locales/$LOCALE/detection.sh"

whiptail --msgbox --ok-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

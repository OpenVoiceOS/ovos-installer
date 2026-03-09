#!/usr/bin/env bash
CONFIG_FILE="${RUN_AS_HOME}/.config/mycroft/mycroft.conf"
OVOS_SERVICE_SCOPE_HINT=""
OVOS_SERVICE_STATUS_COMMAND=""
if [[ "$METHOD" == "containers" ]]; then
    CONFIG_FILE="${RUN_AS_HOME}/ovos/config/mycroft.conf"
elif [[ "${RASPBERRYPI_MODEL:-N/A}" != "N/A" ]] && [[ "${TUNING:-no}" == "yes" ]]; then
    OVOS_SERVICE_STATUS_COMMAND="sudo systemctl status ovos.service"
    if [[ "${FEATURE_GUI:-false}" == "true" ]]; then
        OVOS_SERVICE_STATUS_COMMAND="${OVOS_SERVICE_STATUS_COMMAND} ovos-gui.service"
    fi
    OVOS_SERVICE_SCOPE_HINT="
OVOS services were installed in system systemd scope.

Check them with:
  ${OVOS_SERVICE_STATUS_COMMAND}
"
else
    OVOS_SERVICE_STATUS_COMMAND="systemctl --user status ovos.service"
    if [[ "${FEATURE_GUI:-false}" == "true" ]]; then
        OVOS_SERVICE_STATUS_COMMAND="${OVOS_SERVICE_STATUS_COMMAND} ovos-gui.service"
    fi
    OVOS_SERVICE_SCOPE_HINT="
OVOS services were installed in user systemd scope.

Check them with:
  ${OVOS_SERVICE_STATUS_COMMAND}
"
fi
export CONFIG_FILE OVOS_SERVICE_SCOPE_HINT OVOS_SERVICE_STATUS_COMMAND

# shellcheck source=tui/locales/en-us/finish.sh
source "tui/locales/$LOCALE/finish.sh"

whiptail --msgbox --ok-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh
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
# A satellite cannot grant itself the right to be heard. hivemind-core refuses a
# client every message type until one is allowed explicitly, and
# recognizer_loop:utterance is no longer granted by default - so a satellite
# connects, authenticates, and then has everything it says rejected. The grant
# lives in the listener's database and is made per client, which is why the
# installer cannot make it from here: this machine has neither that database nor
# the hivemind-core command.
#
# Only the first characters of the access key: enough to pick this satellite out of
# list-clients, while an install log stays safe to paste into a bug report.
HIVEMIND_KEY_PREFIX="${SATELLITE_KEY:0:8}"
SHOW_HIVEMIND_SATELLITE_NOTE=""
if [[ "${PROFILE:-}" == "satellite" ]]; then
    SHOW_HIVEMIND_SATELLITE_NOTE="1"
fi
export HIVEMIND_KEY_PREFIX SHOW_HIVEMIND_SATELLITE_NOTE

export CONFIG_FILE OVOS_SERVICE_SCOPE_HINT OVOS_SERVICE_STATUS_COMMAND

# shellcheck source=tui/locales/en-us/finish.sh
source "tui/locales/$LOCALE/finish.sh"
tui_whiptail_dialog_allow_escape --msgbox --ok-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

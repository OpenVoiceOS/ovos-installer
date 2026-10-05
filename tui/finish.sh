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
# Nobody finds this on their own: the package is ovos-tui-client and the command is
# ovos-tui. It talks to the same bus the microphone does, so it answers the question
# people actually have after an install - is OVOS alive, or is this an audio problem -
# and it needs no microphone to do it. A user on Ubuntu Studio put it plainly: "I never
# found how to invoke the text-only GUI ... I'm not certain it ever installed".
#
# Only where the command exists. The virtualenv method installs it with the core and
# server requirements, so every profile but a satellite has it; the containers method
# has it in the ovos_cli container, which only the desktop compositions define.
OVOS_TEXT_CLIENT_COMMAND=""
if [[ "$METHOD" == "containers" ]]; then
    if [[ "${PROFILE:-ovos}" != "satellite" ]] && [[ "${PROFILE:-ovos}" != "server" ]]; then
        OVOS_TEXT_CLIENT_COMMAND="docker exec -it ovos_cli ovos-tui"
    fi
elif [[ "${PROFILE:-ovos}" != "satellite" ]]; then
    OVOS_TEXT_CLIENT_COMMAND="ovos-tui"
fi
OVOS_TEXT_CLIENT_HINT=""
if [[ -n "$OVOS_TEXT_CLIENT_COMMAND" ]]; then
    OVOS_TEXT_CLIENT_HINT="
To talk to it without a microphone, and to see which skill answered:

  ${OVOS_TEXT_CLIENT_COMMAND}
"
fi
export OVOS_TEXT_CLIENT_COMMAND OVOS_TEXT_CLIENT_HINT

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
# Two steps because a substring expansion has no :- form, and every profile that is
# not a satellite reaches here with SATELLITE_KEY unset - under set -u that is fatal,
# and it takes the whole finish screen with it.
hivemind_satellite_key="${SATELLITE_KEY:-}"
HIVEMIND_KEY_PREFIX="${hivemind_satellite_key:0:8}"
SHOW_HIVEMIND_SATELLITE_NOTE=""
if [[ "${PROFILE:-}" == "satellite" ]]; then
    SHOW_HIVEMIND_SATELLITE_NOTE="1"
fi
export HIVEMIND_KEY_PREFIX SHOW_HIVEMIND_SATELLITE_NOTE
export HIVEMIND_HOST="${HIVEMIND_HOST:-}" HIVEMIND_PORT="${HIVEMIND_PORT:-}"

export CONFIG_FILE OVOS_SERVICE_SCOPE_HINT OVOS_SERVICE_STATUS_COMMAND

# shellcheck source=tui/locales/en-us/finish.sh
source "tui/locales/$LOCALE/finish.sh"
tui_whiptail_dialog_allow_escape --msgbox --ok-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" "$TUI_WINDOW_HEIGHT" "$TUI_WINDOW_WIDTH"

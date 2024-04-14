#!/bin/bash

HIVEMIND_HOST=$(whiptail --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_HOST" "$CONTENT_HOST" 25 80 3>&1 1>&2 2>&3)

exit_status=$?

if [ "$exit_status" -eq 0 ]; then
    export HIVEMIND_HOST
else
    source tui/profiles.sh
    if [[ "$PROFILE" == "satellite" ]]; then
        source tui/satellite/host.sh
    else
        BACK_STATUS=1
        source tui/features.sh
        export BACK_STATUS
    fi
fi

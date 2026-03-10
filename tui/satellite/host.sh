#!/bin/bash
# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh

if tui_whiptail_capture HIVEMIND_HOST --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_HOST" "$CONTENT_HOST" 25 80; then
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

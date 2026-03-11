#!/bin/bash
# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh

if tui_whiptail_capture SATELLITE_PASSWORD --passwordbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_PASSWORD" "$CONTENT_PASSWORD" 25 80; then
    export SATELLITE_PASSWORD BACK_STATUS=1
else
    export BACK_STATUS=-1
fi

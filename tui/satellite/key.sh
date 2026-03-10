#!/bin/bash
# shellcheck source=tui/dialogs.sh
source tui/dialogs.sh

if tui_whiptail_capture SATELLITE_KEY --passwordbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_KEY" "$CONTENT_KEY" 25 80; then
    export SATELLITE_KEY
else
    export BACK_STATUS=-1
fi

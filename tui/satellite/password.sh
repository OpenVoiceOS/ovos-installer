#!/bin/bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh

if tui_nav_capture SATELLITE_PASSWORD --passwordbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_PASSWORD" "$CONTENT_PASSWORD" 25 80; then
    export SATELLITE_PASSWORD BACK_STATUS=1
else
    export BACK_STATUS=-1
fi

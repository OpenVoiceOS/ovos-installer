#!/bin/bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh

if tui_nav_capture SATELLITE_KEY --passwordbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_KEY" "$CONTENT_KEY" 25 80; then
    export SATELLITE_KEY
else
    export BACK_STATUS=-1
fi

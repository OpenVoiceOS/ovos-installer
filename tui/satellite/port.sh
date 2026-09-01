#!/bin/bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh

if tui_nav_capture HIVEMIND_PORT --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_PORT" "$CONTENT_PORT" 25 80 5678; then
    export HIVEMIND_PORT
else
    export BACK_STATUS=-1
fi

#!/bin/bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh

if tui_nav_capture HIVEMIND_HOST --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_HOST" "$CONTENT_HOST" 25 80; then
    export HIVEMIND_HOST
else
    export BACK_STATUS=-1
fi

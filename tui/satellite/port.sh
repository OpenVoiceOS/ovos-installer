#!/bin/bash

HIVEMIND_PORT=$(whiptail --inputbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_PORT" "$CONTENT_PORT" 25 80 5678 3>&1 1>&2 2>&3)

exit_status=$?

if [ $exit_status == 0 ]; then
    export HIVEMIND_PORT
else
    export BACK_STATUS=-1
fi
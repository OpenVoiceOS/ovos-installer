#!/bin/bash

SATELLITE_KEY=$(whiptail --passwordbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_KEY" "$CONTENT_KEY" 25 80 3>&1 1>&2 2>&3)

exit_status=$?

if [ $exit_status == 0 ]; then
    export SATELLITE_KEY
else
    export BACK_STATUS=-1
fi
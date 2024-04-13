#!/bin/bash

SATELLITE_PASSWORD=$(whiptail --passwordbox --cancel-button "$BACK_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_PASSWORD" "$CONTENT_PASSWORD" 25 80 3>&1 1>&2 2>&3)

exit_status=$?

if [ $exit_status == 0 ]; then
    export SATELLITE_PASSWORD BACK_STATUS=1
else
    export BACK_STATUS=-1
fi
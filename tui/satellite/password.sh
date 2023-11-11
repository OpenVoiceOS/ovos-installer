#!/bin/bash

SATELLITE_PASSWORD=$(whiptail --passwordbox --cancel-button "$CANCEL_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_PASSWORD" "$CONTENT_PASSWORD" 25 80 3>&1 1>&2 2>&3)
export SATELLITE_PASSWORD

exit_status=$?
if [ "$exit_status" = 1 ]; then
  exit 1
fi

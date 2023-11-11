#!/bin/bash

SATELLITE_KEY=$(whiptail --passwordbox --cancel-button "$CANCEL_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_KEY" "$CONTENT_KEY" 25 80 3>&1 1>&2 2>&3)
export SATELLITE_KEY

exit_status=$?
if [ "$exit_status" = 1 ]; then
  exit 1
fi

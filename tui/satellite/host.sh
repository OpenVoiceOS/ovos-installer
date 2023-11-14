#!/bin/bash

HIVEMIND_HOST=$(whiptail --inputbox --cancel-button "$CANCEL_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_HOST" "$CONTENT_HOST" 25 80 3>&1 1>&2 2>&3)
export HIVEMIND_HOST

exit_status=$?
if [ "$exit_status" -eq 1 ]; then
  exit 1
fi

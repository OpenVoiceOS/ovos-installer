#!/bin/bash

HIVEMIND_PORT=$(whiptail --inputbox --cancel-button "$CANCEL_BUTTON" --ok-button "$OK_BUTTON" --title "$TITLE_PORT" "$CONTENT_PORT" 25 80 5678 3>&1 1>&2 2>&3)
export HIVEMIND_PORT

exit_status=$?
if [ "$exit_status" -eq 1 ]; then
  exit 1
fi


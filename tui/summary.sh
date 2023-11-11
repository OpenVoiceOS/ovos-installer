#!/bin/env bash

source "tui/locales/$LOCALE/summary.sh"

whiptail --yesno --defaultno --no-button "$CANCEL_BUTTON" --yes-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" 25 80

exit_status=$?
if [ "$exit_status" = 1 ]; then
  exit 1
fi

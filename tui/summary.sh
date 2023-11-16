#!/bin/env bash

# shellcheck source=locales/en-us/summary.sh
source "tui/locales/$LOCALE/summary.sh"

whiptail --yesno --defaultno --no-button "$CANCEL_BUTTON" --yes-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" 25 80

exit_status=$?
if [ "$exit_status" -eq 1 ]; then
  exit 0
fi

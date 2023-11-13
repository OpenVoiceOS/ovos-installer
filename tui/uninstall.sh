#!/bin/env bash

export CONFIRM_UNINSTALL="true"

source "tui/locales/$LOCALE/misc.sh"
source "tui/locales/$LOCALE/uninstall.sh"

whiptail --yesno --defaultno --no-button "$CANCEL_BUTTON" --yes-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" 25 80

exit_status=$?
if [ "$exit_status" -eq 1 ]; then
  export CONFIRM_UNINSTALL="false"
fi

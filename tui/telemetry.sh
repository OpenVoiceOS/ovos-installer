#!/bin/env bash

export SHARE_TELEMETRY="true"

# shellcheck source=locales/en-us/telemetry.sh
source "tui/locales/$LOCALE/telemetry.sh"

whiptail --yesno --no-button "$CANCEL_BUTTON" --yes-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" 25 80

exit_status=$?
if [ "$exit_status" -eq 1 ]; then
  export SHARE_TELEMETRY="false"
fi

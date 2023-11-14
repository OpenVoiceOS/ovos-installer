#!/bin/env bash

# shellcheck source=locales/en-us/detection.sh
source "tui/locales/$LOCALE/detection.sh"

whiptail --msgbox --ok-button "$OK_BUTTON" --title "$TITLE" "$CONTENT" 25 80

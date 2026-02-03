#!/bin/env bash

# shellcheck source=tui/locales/en-us/satellite.sh
source "tui/locales/$LOCALE/satellite.sh"

BACK_STATUS=0
current_index=0
scripts=("tui/satellite/host.sh" "tui/satellite/port.sh" "tui/satellite/key.sh" "tui/satellite/password.sh")

while :; do
    if [ "$BACK_STATUS" -eq 1 ]; then
        break
    fi

    # shellcheck disable=SC1091
    source "${scripts[$current_index]}"

    if [ "$BACK_STATUS" -eq 1 ]; then
        break
    fi

    if [ "$BACK_STATUS" -eq -1 ]; then
        BACK_STATUS=0
        if [ "$current_index" -eq 0 ]; then
            source tui/features.sh
            break
        else
            current_index=$((current_index - 1))
        fi
    else
        current_index=$((current_index + 1))
    fi
done

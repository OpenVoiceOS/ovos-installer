#!/usr/bin/env bash
# shellcheck source=tui/navigation.sh
source tui/navigation.sh
# shellcheck source=tui/locales/en-us/satellite.sh
source "tui/locales/$LOCALE/satellite.sh"

# The HiveMind questions are a sub-flow: BACK_STATUS moves between them, and
# only the two ends of it hand control back to tui/main.sh.
#   -1  the user asked to go back
#    1  the sub-flow is complete
BACK_STATUS=0
current_index=0
scripts=("tui/satellite/host.sh" "tui/satellite/port.sh" "tui/satellite/key.sh" "tui/satellite/password.sh")

while :; do
    # shellcheck disable=SC1091
    source "${scripts[$current_index]}"

    if [ "$BACK_STATUS" -eq 1 ]; then
        break
    fi

    if [ "$BACK_STATUS" -eq -1 ]; then
        BACK_STATUS=0
        if [ "$current_index" -eq 0 ]; then
            # Back from the first question leaves the sub-flow entirely.
            tui_nav_set "back"
            return 0
        fi
        current_index=$((current_index - 1))
    else
        current_index=$((current_index + 1))
    fi
done

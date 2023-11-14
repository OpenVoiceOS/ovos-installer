#!/bin/env bash

# shellcheck source=locales/en-us/misc.sh
source "tui/locales/$LOCALE/misc.sh"

# shellcheck source=welcome.sh
source tui/welcome.sh

# shellcheck source=detection.sh
source tui/detection.sh

# shellcheck source=methods.sh
source tui/methods.sh

# shellcheck source=channels.sh
source tui/channels.sh

# shellcheck source=profiles.sh
source tui/profiles.sh

if [[ "$PROFILE" != "satellite" ]]; then
    # shellcheck source=features.sh
    source tui/features.sh
else
    export FEATURE_GUI="false"
    export FEATURE_SKILLS="false"
fi

if [[ "$PROFILE" == "satellite" ]]; then
    # shellcheck source=satellite/main.sh
    source tui/satellite/main.sh
fi

if [[ "$RASPBERRYPI_MODEL" != "N/A" ]]; then
    # shellcheck source=tuning.sh
    source tui/tuning.sh
else 
    export TUNING="no"
fi

# shellcheck source=summary.sh
source tui/summary.sh

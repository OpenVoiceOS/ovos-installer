#!/bin/env bash

source tui/welcome.sh
source tui/detection.sh
source tui/methods.sh
source tui/channels.sh
source tui/profiles.sh
if [[ "$PROFILE" != "satellite" ]]; then
    source tui/features.sh
else
    export FEATURE_GUI="false"
    export FEATURE_SKILLS="false"
fi
if [[ "$PROFILE" == "satellite" ]]; then
    # source tui/satellite/main.sh
    source tui/satellite.sh
fi
if [[ "$RASPBERRYPI_MODEL" != "N/A" ]]; then
    source tui/tuning.sh
fi
source tui/summary.sh

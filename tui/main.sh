#!/usr/bin/env bash
# shellcheck source=tui/locales/en-us/misc.sh
source "tui/locales/$LOCALE/misc.sh"

# shellcheck source=tui/welcome.sh
source tui/welcome.sh

# shellcheck source=tui/detection.sh
source tui/detection.sh

# shellcheck source=tui/methods.sh
source tui/methods.sh

# shellcheck source=tui/channels.sh
source tui/channels.sh

# shellcheck source=tui/profiles.sh
source tui/profiles.sh

if [[ "$PROFILE" != "satellite" ]]; then
    # shellcheck source=tui/features.sh
    source tui/features.sh
else
    export FEATURE_GUI="false"
    export FEATURE_SKILLS="false"
fi

if [[ "$PROFILE" == "satellite" ]]; then
    # shellcheck source=tui/satellite/main.sh
    source tui/satellite/main.sh
fi

if [[ "$RASPBERRYPI_MODEL" != "N/A" ]]; then
    # shellcheck source=tui/tuning.sh
    source tui/tuning.sh
else
    export TUNING="no"
fi

# shellcheck source=tui/summary.sh
source tui/summary.sh

# shellcheck source=tui/telemetry.sh
source tui/telemetry.sh

# shellcheck source=tui/usage_telemetry.sh
source tui/usage_telemetry.sh

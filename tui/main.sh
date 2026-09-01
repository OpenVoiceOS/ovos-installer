#!/usr/bin/env bash
# Drives the installer TUI.
#
# The screens are steps in a list instead of a chain of nested `source` calls:
# each one reports next/back/repeat through TUI_NAV and returns here. Going
# back therefore costs nothing, works from every screen, and keeps going all
# the way down to the language picker.

# shellcheck source=tui/navigation.sh
source tui/navigation.sh

# Values the rest of the installer expects from screens this run skips.
if [[ "${RASPBERRYPI_MODEL:-N/A}" == "N/A" ]]; then
    export TUNING="no"
fi

if [[ "${EXISTING_INSTANCE:-false}" == "true" ]]; then
    export SHARE_TELEMETRY="false"
    export SHARE_USAGE_TELEMETRY="false"
fi

tui_step_index=0

while [ "$tui_step_index" -lt "${#TUI_FLOW[@]}" ]; do
    tui_step="${TUI_FLOW[$tui_step_index]}"

    if ! tui_flow_step_enabled "$tui_step"; then
        tui_step_index="$(tui_flow_next_index "$tui_step_index")"
        continue
    fi

    tui_nav_reset

    case "$tui_step" in
    uninstall)
        # shellcheck source=tui/uninstall.sh
        source tui/uninstall.sh
        ;;
    update)
        # shellcheck source=tui/update.sh
        source tui/update.sh
        ;;
    welcome)
        # shellcheck source=tui/welcome.sh
        source tui/welcome.sh
        ;;
    hardware_confirmation)
        # shellcheck source=tui/hardware_confirmation.sh
        source tui/hardware_confirmation.sh
        ;;
    detection)
        # shellcheck source=tui/detection.sh
        source tui/detection.sh
        ;;
    methods)
        # shellcheck source=tui/methods.sh
        source tui/methods.sh
        ;;
    channels)
        # shellcheck source=tui/channels.sh
        source tui/channels.sh
        ;;
    profiles)
        # shellcheck source=tui/profiles.sh
        source tui/profiles.sh
        ;;
    features)
        # shellcheck source=tui/features.sh
        source tui/features.sh
        ;;
    satellite)
        # A satellite has no feature checklist, it collects HiveMind settings.
        export FEATURE_GUI="false"
        export FEATURE_SKILLS="false"
        export FEATURE_LLM="false"
        # shellcheck source=tui/satellite/main.sh
        source tui/satellite/main.sh
        ;;
    tuning)
        # shellcheck source=tui/tuning.sh
        source tui/tuning.sh
        ;;
    summary)
        # shellcheck source=tui/summary.sh
        source tui/summary.sh
        ;;
    telemetry)
        # shellcheck source=tui/telemetry.sh
        source tui/telemetry.sh
        ;;
    usage_telemetry)
        # shellcheck source=tui/usage_telemetry.sh
        source tui/usage_telemetry.sh
        ;;
    esac

    # Uninstalling asks nothing else: there is no install to configure.
    if [ "${CONFIRM_UNINSTALL:-false}" == "true" ] && [ "${TUI_NAV:-next}" == "next" ]; then
        break
    fi

    case "${TUI_NAV:-next}" in
    back)
        tui_previous_index="$(tui_flow_previous_index "$tui_step_index")"

        if [ "$tui_previous_index" -lt 0 ]; then
            # Nothing precedes the first screen but the language picker, and
            # its own cancel button leaves the installer. Tell it this is a
            # return visit, so that leaving asks for confirmation.
            export TUI_LANGUAGE_REVISITED="true"
            # shellcheck source=tui/language.sh
            source tui/language.sh
            tui_nav_load_strings
            tui_step_index=0
        else
            tui_step_index="$tui_previous_index"
        fi
        ;;
    repeat)
        # Render the same screen again. utils/common.sh turns errexit back on
        # for the rest of the TUI, so this branch needs a command of its own.
        :
        ;;
    *)
        tui_step_index="$(tui_flow_next_index "$tui_step_index")"
        ;;
    esac
done

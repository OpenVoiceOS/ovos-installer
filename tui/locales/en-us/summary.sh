#!/usr/bin/env bash
HOMEASSISTANT_SUMMARY_STATE="disabled"
if [ "${FEATURE_HOMEASSISTANT:-false}" == "true" ]; then
    if [ "${PROFILE:-}" == "server" ] || [ "${PROFILE:-}" == "satellite" ]; then
        HOMEASSISTANT_SUMMARY_STATE="selected (not supported for this profile)"
    elif [ -n "${HOMEASSISTANT_URL:-}" ]; then
        HOMEASSISTANT_SUMMARY_STATE="enabled"
    else
        HOMEASSISTANT_SUMMARY_STATE="selected (missing URL; will be skipped)"
    fi
fi

CONTENT="
You are almost done, here is a summary of choices you made to install Open Voice OS:

    - Method:   $METHOD
    - Version:  $CHANNEL
    - Profile:  $PROFILE
    - Skills:   $FEATURE_SKILLS
    - Extra:    $FEATURE_EXTRA_SKILLS
    - Home Assistant: $HOMEASSISTANT_SUMMARY_STATE
    - Tuning:   $TUNING

The choices made during the Open Voice OS installation process have been carefully considered to tailor our system to your unique needs and preferences.

Does this summary look correct to you? If not, select $BACK_BUTTON (or press ESC) to go back and make changes.
"
TITLE="Open Voice OS Installation - Summary"

export CONTENT TITLE

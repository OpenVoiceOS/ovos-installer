#!/usr/bin/env bash
CONTENT="
You are almost done, here is a summary of choices you made to install Open Voice OS:

    - Method:   ${METHOD:-}
    - Version:  ${CHANNEL:-}
    - Profile:  ${PROFILE:-}
    - Skills:   ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Extra:    ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - HA:       ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM:      ${LLM_SUMMARY_STATE:-}
    - Tuning:   ${TUNING_SUMMARY_STATE:-}

The choices made during the Open Voice OS installation process have been carefully considered to tailor our system to your unique needs and preferences.

Does this summary look correct to you? If not, select ${BACK_BUTTON:-} to go back and make changes.
"
TITLE="Open Voice OS Installation - Summary"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION

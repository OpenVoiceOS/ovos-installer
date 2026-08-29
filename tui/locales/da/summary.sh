#!/usr/bin/env bash
CONTENT="
Du er næsten færdig, her er en oversigt over de valg, du har truffet for at installere Open Voice OS:

    - Metode: ${METHOD:-}
    - Version: ${CHANNEL:-}
    - Profil: ${PROFILE:-}
    - Færdigheder: ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Tuning: ${TUNING_SUMMARY_STATE:-}

De valg, der blev truffet under installationen af ​​Open Voice OS, er blevet nøje overvejet for at skræddersy vores system til dine unikke behov og præferencer.

Ser denne oversigt korrekt ud for dig? Hvis ikke, vælg ${BACK_BUTTON:-} (eller tryk ESC) for at gå tilbage og foretage ændringer.
"
TITLE="Open Voice OS Installation - Resume"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION

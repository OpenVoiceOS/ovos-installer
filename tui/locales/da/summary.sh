#!/usr/bin/env bash
CONTENT="
Du er næsten færdig, her er en oversigt over de valg, du har truffet for at installere Open Voice OS:

    - Metode:             ${METHOD:-}
    - Version:            ${CHANNEL:-}
    - Profil:             ${PROFILE:-}
    - Færdigheder:        ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Ekstra færdigheder: ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - Home Assistant:     ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM:                ${LLM_SUMMARY_STATE:-}
    - Tale:               ${SPEECH_SUMMARY_STATE:-}
    - Tuning:             ${TUNING_SUMMARY_STATE:-}

De valg, der blev truffet under installationen af ​​Open Voice OS, er blevet nøje overvejet for at skræddersy vores system til dine unikke behov og præferencer.

Ser denne oversigt korrekt ud for dig? Hvis ikke, vælg ${BACK_BUTTON:-} for at gå tilbage og foretage ændringer.
"
TITLE="Open Voice OS Installation - Resume"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"
SUMMARY_SPEECH_LOCAL="på denne maskine"
SUMMARY_SPEECH_PUBLIC="offentlige servere"
SUMMARY_SPEECH_PUBLIC_HARDWARE="offentlige servere (lokal: Pi 5 med 8 GB eller mere)"
SUMMARY_SPEECH_PUBLIC_SETUP="offentlige servere (lokal er ikke tilgængelig her)"
SUMMARY_SPEECH_UNUSED="bruges ikke af denne profil"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION SUMMARY_SPEECH_LOCAL SUMMARY_SPEECH_PUBLIC SUMMARY_SPEECH_PUBLIC_HARDWARE SUMMARY_SPEECH_PUBLIC_SETUP SUMMARY_SPEECH_UNUSED

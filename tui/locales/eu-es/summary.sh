#!/usr/bin/env bash
CONTENT="
Ia amaitu duzu, hona hemen Open Voice OS instalatzeko egin dituzun aukeren laburpena:

    - Metodoa:                ${METHOD:-}
    - Bertsioa:               ${CHANNEL:-}
    - Profila:                ${PROFILE:-}
    - Trebetasunak:           ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Trebetasun gehigarriak: ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - Home Assistant:         ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM:                    ${LLM_SUMMARY_STATE:-}
    - Afinazioa:              ${TUNING_SUMMARY_STATE:-}

Open Voice OS instalazio-prozesuan egindako aukerak arretaz aztertu dira gure sistema zure behar eta lehentasun berezietara egokitzeko.

Laburpen hau zuzena iruditzen zaizu? Hala ez bada, hautatu ${BACK_BUTTON:-} (edo sakatu ESC) atzera egiteko eta aldaketak egiteko.
"
TITLE="Ireki Voice OS instalazioa - Laburpena"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION

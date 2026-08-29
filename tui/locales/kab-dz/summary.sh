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

LLM_SUMMARY_STATE="disabled"
if [ "${FEATURE_LLM:-false}" == "true" ]; then
    if [ "${PROFILE:-}" == "server" ] || [ "${PROFILE:-}" == "satellite" ]; then
        LLM_SUMMARY_STATE="selected (not supported for this profile)"
    elif [ -n "${LLM_API_URL:-}" ] && [ -n "${LLM_API_KEY:-}" ] && [ -n "${LLM_MODEL:-}" ] && [ -n "${LLM_PERSONA:-}" ]; then
        LLM_SUMMARY_STATE="enabled"
    else
        LLM_SUMMARY_STATE="selected (missing configuration; will be skipped)"
    fi
fi

CONTENT="
Qrib ad tekfuḍ, ha-t-an ugzul n textiṛiyin i tgiḍ akken ad tesbeddeḍ anagraw n Open Voice OS

    - Tarrayt:   $METHOD
    - Lqem:  $CHANNEL
    - Amaɣnu:  $PROFILE
    - Tussniwin:  $FEATURE_SKILLS_SUMMARY_STATE
    - Tussniwin timernanin:  $FEATURE_EXTRA_SKILLS_SUMMARY_STATE
    - Home Assistant:  $HOMEASSISTANT_SUMMARY_STATE
    - LLM:  $LLM_SUMMARY_STATE
    - Tamellit:   $TUNING_SUMMARY_STATE

Ifranen i d-yettwaxedmen deg ukala n usbeddi n Open Voice OS ttwafernen s ttawil akked ufeṣṣel i wakken ad yeddu unagraw-nneɣ akken i teḥwaǧeḍ.

Yettban-ak-d iṣeḥḥa ugzul-a? Ma ulac, fren $BACK_BUTTON (neɣ sit ɣef ESC) akken ad tuɣaleḍ ɣer deffir ad tbeddleḍ.
"
TITLE="Asbeddi n Open Voice OS - Agzul"

export CONTENT TITLE

#!/usr/bin/env bash
CONTENT="
Qrib ad tekfuḍ, ha-t-an ugzul n textiṛiyin i tgiḍ akken ad tesbeddeḍ anagraw n Open Voice OS

    - Tarrayt:   ${METHOD:-}
    - Lqem:  ${CHANNEL:-}
    - Amaɣnu:  ${PROFILE:-}
    - Tussniwin:  ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Tussniwin timernanin:  ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - Home Assistant:  ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM:  ${LLM_SUMMARY_STATE:-}
    - Taɣect: ${SPEECH_SUMMARY_STATE:-}
    - Tamellit:   ${TUNING_SUMMARY_STATE:-}

Ifranen i d-yettwaxedmen deg ukala n usbeddi n Open Voice OS ttwafernen s ttawil akked ufeṣṣel i wakken ad yeddu unagraw-nneɣ akken i teḥwaǧeḍ.

Yettban-ak-d iṣeḥḥa ugzul-a? Ma ulac, fren ${BACK_BUTTON:-} akken ad tuɣaleḍ ɣer deffir ad tbeddleḍ.
"
TITLE="Asbeddi n Open Voice OS - Agzul"

SUMMARY_STATE_ENABLED="d urmid"
SUMMARY_STATE_DISABLED="d arurmid"
SUMMARY_STATE_UNSUPPORTED_PROFILE="yettawfran (ur yettwasefrek ara deg umaɣnu-a)"
SUMMARY_STATE_MISSING_URL="yettwafran (txuṣṣ URL; as yettwazgal)"
SUMMARY_STATE_MISSING_CONFIGURATION="yettwafran (txuṣṣ tawila; as yettwazgal)"
SUMMARY_SPEECH_LOCAL="ɣef tmacint-a s yiqeddacen izayazen d tallalt"
SUMMARY_SPEECH_PUBLIC="iqeddacen izayazen"
SUMMARY_SPEECH_PUBLIC_HARDWARE="iqeddacen izayazen (adigan: Pi 5 s 8 GB neɣ ugar)"
SUMMARY_SPEECH_PUBLIC_SETUP="iqeddacen izayazen (adigan ulac-it dagi)"
SUMMARY_SPEECH_UNUSED="ur yettwaseqdac ara deg umaɣnu-a"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION SUMMARY_SPEECH_LOCAL SUMMARY_SPEECH_PUBLIC SUMMARY_SPEECH_PUBLIC_HARDWARE SUMMARY_SPEECH_PUBLIC_SETUP SUMMARY_SPEECH_UNUSED

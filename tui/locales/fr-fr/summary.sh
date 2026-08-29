#!/usr/bin/env bash
CONTENT="
Vous y êtes presque ! Voici un résumé des choix que vous avez effectués pour l'installation d'Open Voice OS :

    - Méthode d'installation :      ${METHOD:-}
    - Canal de déploiement :        ${CHANNEL:-}
    - Profil d'installation :       ${PROFILE:-}
    - Compétences par défaut :      ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Compétences supplémentaires : ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - Home Assistant :              ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM :                         ${LLM_SUMMARY_STATE:-}
    - Réglages Raspberry Pi :       ${TUNING_SUMMARY_STATE:-}

Les choix effectués lors du processus d'installation d'Open Voice OS ont été soigneusement étudiés pour adapter notre système à vos besoins et préférences.

Est-ce que tout cela vous semble correct ? Sinon, sélectionnez ${BACK_BUTTON:-} (ou appuyez sur ESC) pour revenir en arrière et modifier vos choix.
"
TITLE="Open Voice OS Installation - Résumé"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION

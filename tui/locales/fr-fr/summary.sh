#!/usr/bin/env bash
CONTENT="
Vous y êtes presque ! Voici un résumé des choix que vous avez effectués pour l'installation d'Open Voice OS :

    - Méthode d'installation :   $METHOD
    - Canal de déploiement :      $CHANNEL
    - Profil d'installation :    $PROFILE
    - Compétences par défaut :   $FEATURE_SKILLS
    - Réglages Raspberry Pi :    $TUNING

Les choix effectués lors du processus d'installation d'Open Voice OS ont été soigneusement étudiés pour adapter notre système à vos besoins et préférences.

Est-ce que tout cela vous semble correct ? Sinon, sélectionnez $BACK_BUTTON (ou appuyez sur ESC) pour revenir en arrière et modifier vos choix.
"
TITLE="Open Voice OS Installation - Résumé"

export CONTENT TITLE

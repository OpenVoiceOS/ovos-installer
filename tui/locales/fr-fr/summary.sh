#!/bin/env bash

CONTENT="
Vous y êtes presque! Voici un résumé des choix que vous avez effectués pour l'installation d'Open Voice OS:

    - Méthode d'installation:   $METHOD
    - Canal de déployment:      $CHANNEL
    - Profil d'installation:    $PROFILE
    - Interface graphique:      $FEATURE_GUI
    - Compétences par défaut    $FEATURE_SKILLS    
    - Réglages Raspberry Pi:    $TUNING

Les choix effectués lors du processus d'installation d'Open Voice OS ont été soigneusement étudiés pour adapter notre système à vos besoins et préférences.

Est-ce que tout cela vous semble correct?
"
TITLE="Open Voice OS Installation - Résumé"

export CONTENT TITLE

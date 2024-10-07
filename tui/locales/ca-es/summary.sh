#!/bin/env bash

CONTENT="
Gairebé heu acabat, aquí teniu un resum de les opcions que heu triat en instal·lar l'Open Voice OS:

    - Mètode: $METHOD
    - Versió: $CHANNEL
    - Perfil: $PROFILE
    - IGU: $FEATURE_GUI
    - Habilitats: $FEATURE_SKILLS
    - Afinació: $TUNING

Les opcions selecciondes durant el procés d'instal·lació de l'Open Voice OS s'han considerat acuradament per a adaptar el nostre sistema a les vostres necessitats i preferències úniques.

Us sembla correcte aquest resum? Si no, podeu tornar enrere i fer-hi canvis.
"
TITLE="Instal·lació de l'Open VoiceOS - Resum"

export CONTENT TITLE

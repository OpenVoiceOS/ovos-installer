#!/usr/bin/env bash
CONTENT="
Gairebé heu acabat, aquí teniu un resum de les opcions que heu triat en instal·lar l'Open Voice OS:

    - Mètode: $METHOD
    - Versió: $CHANNEL
    - Perfil: $PROFILE
    - Habilitats: $FEATURE_SKILLS
    - Afinació: $TUNING

Les opcions seleccionades durant el procés d'instal·lació de l'Open Voice OS s'han considerat acuradament per a adaptar el nostre sistema a les vostres necessitats i preferències úniques.

Us sembla correcte aquest resum? Si no, selecciona $BACK_BUTTON (o prem ESC) per tornar enrere i fer canvis.
"
TITLE="Instal·lació de l'Open VoiceOS - Resum"

export CONTENT TITLE

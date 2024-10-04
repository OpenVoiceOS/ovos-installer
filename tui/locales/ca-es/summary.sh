#!/bin/env bash

CONTENT="
Gairebé heu acabat, aquí teniu un resum de les opcions que heu fet per instal·lar Open Voice OS:

    - Mètode: $METHOD
    - Versió: $CHANNEL
    - Perfil: $PROFILE
    - GUI: $FEATURE_GUI
    - Habilitats: $FEATURE_SKILLS
    - Afinació: $TUNING

Les eleccions preses durant el procés d'instal·lació del sistema operatiu Open Voice s'han considerat acuradament per adaptar el nostre sistema a les vostres necessitats i preferències úniques.

Us sembla correcte aquest resum? Si no, podeu tornar enrere i fer canvis.
"
TITLE="Instal·lació del sistema operatiu de veu oberta: resum"

export CONTENT TITLE

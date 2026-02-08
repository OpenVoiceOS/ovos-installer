#!/usr/bin/env bash
CONTENT="
Bijna klaar. Een korte samenvatting:

    - Omgeving: $METHOD
    - Versie:   $CHANNEL
    - Profiel:  $PROFILE
    - Skills:   $FEATURE_SKILLS
    - Tuning:   $TUNING

De beslissingen die zijn genomen tijdens het installatieproces van OpenVoice OS zijn zorgvuldig gemaakt om ons systeem aan te passen aan je individuele behoeften en voorkeuren.

Zijn de instellingen zo in orde? Zo niet, kies $BACK_BUTTON (of druk op ESC) om terug te gaan en wijzigingen te maken.
"
TITLE="OpenVoice OS Installatie - Samenvatting"

export CONTENT TITLE

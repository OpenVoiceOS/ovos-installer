#!/bin/env bash

CONTENT="
Bijna klaar. Een korte samenvatting:

    - Omgeving: $METHOD
    - Versie:   $CHANNEL
    - Profiel:  $PROFILE
    - GUI:      $FEATURE_GUI
    - Skills:   $FEATURE_SKILLS
    - Tuning:   $TUNING

De beslissingen die zijn genomen tijdens het installatieproces van Open Voice OS zijn zorgvuldig overwogen om ons systeem aan te passen aan je individuele behoeften en voorkeuren.

Zijn de instellingen correct?
"
TITLE="Open Voice OS Installatie - Samenvatting"

export CONTENT TITLE

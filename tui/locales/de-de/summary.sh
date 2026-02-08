#!/usr/bin/env bash
CONTENT="
Fast fertig. Eine kurze Zusammenfassung:

    - Umgebung: $METHOD
    - Version:  $CHANNEL
    - Profil:   $PROFILE
    - Skills:   $FEATURE_SKILLS
    - Tuning:   $TUNING

Die Entscheidungen, die während des Installationsprozesses von Open Voice OS getroffen werden, wurden sorgfältig abgewogen, um unser System an Ihre individuellen Bedürfnisse und Vorlieben anzupassen.

Stimmen die Einstellungen? Falls nicht, wählen Sie $BACK_BUTTON (oder drücken Sie ESC), um zurückzugehen und Änderungen vorzunehmen.
"
TITLE="Open Voice OS Installation - Zusammenfassung"

export CONTENT TITLE

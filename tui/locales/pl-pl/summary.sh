#!/usr/bin/env bash
CONTENT="
Już prawie skończyłeś, oto podsumowanie wyborów dokonanych podczas instalacji Open Voice OS:

- Metoda: $METHOD
- Wersja: $CHANNEL
- Profil: $PROFILE
- Umiejętności: $FEATURE_SKILLS_SUMMARY_STATE
- Strojenie: $TUNING_SUMMARY_STATE

Wybory dokonane podczas instalacji Open Voice OS zostały starannie rozważone, aby dostosować nasz system do Twoich unikalnych potrzeb i preferencji.

Czy to podsumowanie wydaje Ci się poprawne? Jeśli nie, wybierz $BACK_BUTTON (lub naciśnij ESC), aby wrócić i wprowadzić zmiany.
"
TITLE="Instalacja Open Voice OS – Podsumowanie"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION

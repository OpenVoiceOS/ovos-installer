#!/usr/bin/env bash
CONTENT="
Już prawie skończyłeś, oto podsumowanie wyborów dokonanych podczas instalacji Open Voice OS:

- Metoda: $METHOD
- Wersja: $CHANNEL
- Profil: $PROFILE
- Umiejętności: $FEATURE_SKILLS
- Strojenie: $TUNING

Wybory dokonane podczas instalacji Open Voice OS zostały starannie rozważone, aby dostosować nasz system do Twoich unikalnych potrzeb i preferencji.

Czy to podsumowanie wydaje Ci się poprawne? Jeśli nie, wybierz $BACK_BUTTON (lub naciśnij ESC), aby wrócić i wprowadzić zmiany.
"
TITLE="Instalacja Open Voice OS – Podsumowanie"

export CONTENT TITLE

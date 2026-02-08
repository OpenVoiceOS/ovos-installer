#!/usr/bin/env bash
CONTENT="
Du er næsten færdig, her er en oversigt over de valg, du har truffet for at installere Open Voice OS:

    - Metode: $METHOD
    - Version: $CHANNEL
    - Profil: $PROFILE
    - Færdigheder: $FEATURE_SKILLS
    - Tuning: $TUNING

De valg, der blev truffet under installationen af ​​Open Voice OS, er blevet nøje overvejet for at skræddersy vores system til dine unikke behov og præferencer.

Ser denne oversigt korrekt ud for dig? Hvis ikke, vælg $BACK_BUTTON (eller tryk ESC) for at gå tilbage og foretage ændringer.
"
TITLE="Open Voice OS Installation - Resume"

export CONTENT TITLE

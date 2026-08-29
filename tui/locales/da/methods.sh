#!/usr/bin/env bash
CONTENT="
For at installere Open Voice OS har du to primære metoder:

    - Containermotor såsom Docker
    - Opsætning af det i et virtuelt Python-miljø

Containere giver isolering og nem implementering, mens et virtuelt Python-miljø giver mere fleksibilitet og kontrol over installationen.

Hvis containermetoden er valgt, installeres Docker automatisk, hvis den ikke findes på systemet.

Vælg venligst en installationsmetode:
"
LOCKED_CONTENT="
Der blev fundet en eksisterende installation af Open Voice OS, så kun den metode, den allerede bruger, er tilgængelig:

    - Fundet metode: ${INSTANCE_TYPE:-}

Hvis du vil installere med en anden metode, skal du først afinstallere den eksisterende instans og derefter køre installationsprogrammet igen.

Bekræft installationsmetoden:
"
TITLE="Open Voice OS Installation - Methoder"

export CONTENT LOCKED_CONTENT TITLE

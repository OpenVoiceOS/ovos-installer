#!/usr/bin/env bash
# The satellite note is defined before CONTENT so CONTENT can interpolate it. It is
# shown only when the caller asks for it, which is only after a satellite install -
# every other profile either runs the listener itself or has nothing to do with one.
# The command names and the values the installer fills in are not translated.
HIVEMIND_SATELLITE_NOTE="
Denne satellit skal stadig have lov til at tale. Tilladelsen gives på maskinen, der kører HiveMind-lytteren på ${HIVEMIND_HOST-}:${HIVEMIND_PORT:-5678}:

  hivemind-core list-clients
  hivemind-core allow-msg recognizer_loop:utterance <node-id>

Brug list-clients til at finde det Node ID, hvis adgangsnøgle begynder ${HIVEMIND_KEY_PREFIX-} - det er denne satellit. Indtil tilladelsen er givet, opretter satellitten forbindelse og bliver godkendt, men alt, hvad den siger, bliver afvist.
"
HIVEMIND_SATELLITE_HINT="${SHOW_HIVEMIND_SATELLITE_NOTE:+$HIVEMIND_SATELLITE_NOTE}"

CONTENT="
Installationen er gennemført med succes! 🎉

Din stemmeassistent er klar til at gå. Vi glæder os til, at du skal udforske den brede vifte af funktioner og muligheder, som denne stemmeassistent har at tilbyde.

Hvis du har aktiveret standardfærdighedsfunktionen, kan du begynde at interagere med din assistent ved at sige:

  - Hej Mycroft, hvad er klokken?
  - Hej Mycroft, hvad er temperaturen?
  - Hej Mycroft, hvem har lavet dig?
  - Hej Mycroft, hvem er Ada Lovelace?
  - Hej Mycroft, hvad ville Duke Nukem sige?

Indstillingerne for din assistent kunne ændres i ${CONFIG_FILE:-}-konfigurationsfilen.

Hvis du har brug for hjælp eller opdateringer i fremtiden, er du velkommen til at kontakte os. Nyd din Open Voice OS-oplevelse!
$HIVEMIND_SATELLITE_HINT
"
TITLE="Open Voice OS Installation - Afslut"

export CONTENT TITLE HIVEMIND_SATELLITE_NOTE HIVEMIND_SATELLITE_HINT

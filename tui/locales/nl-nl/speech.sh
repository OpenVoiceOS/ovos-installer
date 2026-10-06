#!/usr/bin/env bash
CONTENT="
Open Voice OS zet wat je zegt om in tekst (spraakherkenning) en leest zijn antwoorden voor (spraaksynthese). Deze machine is krachtig genoeg om beide zelf te doen.

- local: alles draait op deze machine. Je stem blijft hier, en niets hangt af van internet of van hoe druk de servers zijn. Het installatieprogramma downloadt de spraakmodellen voor je taal, van een paar honderd megabyte tot een paar gigabyte, en de herkenning houdt de processor bezig terwijl je praat.
- public: de openbare servers van Open Voice OS doen het werk. Je hoeft niets te downloaden, maar elk verzoek gaat via internet naar servers die de hele community deelt. Dat voegt netwerkvertraging toe en wordt trager wanneer veel mensen ze tegelijk gebruiken. Je opnames en de antwoorden worden op die servers verwerkt.

Als de lokale herkenning mislukt of niets hoort, wordt die ene opname naar de openbare servers gestuurd.

Selecteer waar spraak wordt verwerkt:
"
TITLE="Open Voice OS Installatie - Spraak"
LOCAL_DESCRIPTION="Spraak op deze machine verwerken"
PUBLIC_DESCRIPTION="De openbare Open Voice OS-servers gebruiken"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

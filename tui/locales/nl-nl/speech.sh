#!/usr/bin/env bash
CONTENT="
Open Voice OS zet wat je zegt om in tekst (spraakherkenning) en leest zijn antwoorden voor (spraaksynthese). Deze machine is krachtig genoeg om beide zelf te doen.

- local: alles draait op deze machine. Je stem blijft hier, en niets hangt af van internet of van hoe druk de servers zijn. Het installatieprogramma downloadt de spraakmodellen voor je taal, van een paar honderd megabyte tot een paar gigabyte, en de herkenning houdt de processor bezig terwijl je praat.
- public: servers van de community doen het werk. Ze draaien uit goede wil, als reserve en als voorbeeld van zelf gehoste spraakverwerking, niet als productiedienst: antwoorden duren langer wanneer veel mensen ze tegelijk gebruiken, en de servers kunnen op elk moment uitvallen. Je hoeft niets te downloaden, maar je opnames en de antwoorden gaan via internet en worden op die servers verwerkt.

Als de lokale herkenning mislukt of niets hoort, wordt die ene opname naar de openbare servers gestuurd.

Selecteer waar spraak wordt verwerkt:
"
TITLE="Open Voice OS Installatie - Spraak"
LOCAL_DESCRIPTION="Spraak op deze machine verwerken"
PUBLIC_DESCRIPTION="Openbare servers (ik weet dat ze kunnen uitvallen)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

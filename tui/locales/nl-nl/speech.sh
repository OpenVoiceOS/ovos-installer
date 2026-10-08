#!/usr/bin/env bash
CONTENT="
Open Voice OS zet spraak om in tekst (herkenning) en leest antwoorden voor (synthese).

  - local: deze machine met openbare servers als reserve. Downloadt spraakmodellen (honderden megabytes tot enkele gigabytes). Als lokale herkenning mislukt of geen tekst oplevert, gaat die opname naar openbare servers. Als lokale herkenning of synthese niet kan worden ingesteld, gebruikt dat onderdeel openbare servers; het installatieprogramma meldt dit.
  - public: servers van de community verwerken je opnames en gesproken antwoorden via internet. Deze reserveservers draaien dankzij vrijwilligers en zijn geen productiedienst: ze kunnen op elk moment traag worden of uitvallen.

Selecteer waar spraak wordt verwerkt:
"
TITLE="Open Voice OS Installatie - Spraak"
LOCAL_DESCRIPTION="Deze machine met openbare servers als reserve"
PUBLIC_DESCRIPTION="Openbare servers (ik weet dat ze kunnen uitvallen)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

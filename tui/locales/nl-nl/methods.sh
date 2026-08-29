#!/usr/bin/env bash
CONTENT="
Er zijn twee omgevingen voor de installatie van OpenVoice OS:

    - Container-methode zoals Docker
    - Installatie in een virtuele Python-omgeving

Containers zorgen voor isolatie en eenvoudige installatie, terwijl een virtuele Python-omgeving meer flexibiliteit en controle over de installatie biedt.

Als de containermethode is geselecteerd, wordt Docker automatisch geïnstalleerd als het niet aanwezig is op je systeem.

Selecteer een installatieomgeving:
"
LOCKED_CONTENT="
Er is een bestaande installatie van Open Voice OS gedetecteerd, daarom is alleen de methode beschikbaar die al wordt gebruikt:

    - Gedetecteerde methode: $INSTANCE_TYPE

Om met een andere methode te installeren, verwijder eerst de bestaande instantie en voer het installatieprogramma opnieuw uit.

Bevestig de installatiemethode:
"
TITLE="OpenVoice OS Installatie - Installatieomgeving"

export CONTENT LOCKED_CONTENT TITLE

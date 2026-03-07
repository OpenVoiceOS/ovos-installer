#!/usr/bin/env bash
CONTENT="
Skills ermöglichen die Interaktion durch Sprache, z. B. für Aufgaben wie Hausautomatisierung, Informationsabfrage und die Steuerung intelligenter Geräte durch Sprachbefehle.

Bitte wählen Sie die zu aktivierenden Funktionen aus:
"
TITLE="Open Voice OS Funktionsauswahl"
SKILL_DESCRIPTION="Laden Sie eine Auswahl an OVOS skills"
EXTRA_SKILL_DESCRIPTION="Laden Sie zusätzliche OVOS-Skills"
HOMEASSISTANT_DESCRIPTION="Home-Assistant-Integration aktivieren (benötigt URL und Token)"
LLM_DESCRIPTION="KI-Gesprächsfallback für OVOS Persona aktivieren (geführte Einrichtung für URL, Schlüssel, Modell, Stil und Antwortabstimmung)"

export CONTENT TITLE SKILL_DESCRIPTION EXTRA_SKILL_DESCRIPTION HOMEASSISTANT_DESCRIPTION LLM_DESCRIPTION

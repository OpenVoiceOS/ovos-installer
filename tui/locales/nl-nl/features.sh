#!/usr/bin/env bash
CONTENT="
Skills maken interactie via spraak mogelijk, waardoor ze efficiënt zijn voor taken zoals domotica, informatie ophalen en slimme apparaten bedienen via spraakopdrachten.

Kies welke functies je wil activeren (meerdere opties tegelijkertijd zijn mogelijk):
"
TITLE="OpenVoice OS Installatie - Kenmerken"
SKILL_DESCRIPTION="Standaard OVOS skills"
EXTRA_SKILL_DESCRIPTION="Extra OVOS skills"
HOMEASSISTANT_DESCRIPTION="Home Assistant-integratie inschakelen (vereist URL en token)"
LLM_DESCRIPTION="AI-gespreksfallback voor OVOS Persona inschakelen (begeleide instelling voor URL, sleutel, model, stijl en antwoordafstemming)"

export CONTENT TITLE SKILL_DESCRIPTION EXTRA_SKILL_DESCRIPTION HOMEASSISTANT_DESCRIPTION LLM_DESCRIPTION

#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS Installatie - LLM"
LLM_CONTENT_HAVE_DETAILS="
Je hebt de LLM-functie voor ovos-persona geselecteerd.

Geef alsjeblieft op:
  - OpenAI-compatibele API-URL
  - API-sleutel
  - Persona-prompt
"
LLM_TITLE_EXISTING="Open Voice OS Installatie - Bestaande LLM-instellingen"
LLM_CONTENT_EXISTING="
Bestaande LLM persona-configuratie gevonden.

API-URL: __URL__

Wil je de bestaande configuratie behouden?
"
LLM_TITLE_URL="Open Voice OS Installatie - LLM API-URL"
LLM_CONTENT_URL="
Voer je OpenAI-compatibele API-URL in.

Voorbeeld: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Open Voice OS Installatie - LLM API-sleutel"
LLM_CONTENT_KEY="
Voer je LLM API-sleutel in.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Laat leeg om je bestaande sleutel te behouden.
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM Model"
LLM_CONTENT_MODEL="
Please enter the LLM model name to use.

Example: gpt-4o-mini
"
LLM_TITLE_PERSONA="Open Voice OS Installatie - LLM Persona"
LLM_CONTENT_PERSONA="
Voer de persona-prompt in die door ovos-persona wordt gebruikt.

Voorbeeld: behulpzaam, creatief, slim en erg vriendelijk.
"
LLM_TITLE_INVALID="Open Voice OS Installatie - Ongeldige LLM-configuratie"
LLM_CONTENT_MISSING_INFO="
Sommige vereiste LLM-informatie ontbreekt.

Geef API-URL, API-sleutel en persona-tekst op.
"
LLM_CONTENT_INVALID_URL="
Ongeldige URL.

Geef een geldige OpenAI-compatibele API-URL op.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

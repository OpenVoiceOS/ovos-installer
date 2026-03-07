#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS Installation - LLM"
LLM_CONTENT_HAVE_DETAILS="
Du har valgt LLM-funktionen til ovos-persona.

Angiv venligst:
  - OpenAI-kompatibel API-URL
  - API-nøgle
  - Model
  - Persona-prompt
"
LLM_TITLE_EXISTING="Open Voice OS Installation - Eksisterende LLM-indstillinger"
LLM_CONTENT_EXISTING="
Eksisterende LLM persona-konfiguration fundet.

API-URL: __URL__

Vil du beholde den eksisterende konfiguration?
"
LLM_TITLE_URL="Open Voice OS Installation - LLM API-URL"
LLM_CONTENT_URL="
Angiv din OpenAI-kompatible API-URL.

Eksempel: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Open Voice OS Installation - LLM API-nøgle"
LLM_CONTENT_KEY="
Angiv din LLM API-nøgle.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Lad feltet være tomt for at beholde din eksisterende nøgle.
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM-model"
LLM_CONTENT_MODEL="
Angiv navnet på den LLM-model, der skal bruges.

Eksempel: gpt-4o-mini
"
LLM_TITLE_PERSONA="Open Voice OS Installation - LLM Persona"
LLM_CONTENT_PERSONA="
Angiv persona-prompten, der bruges af ovos-persona.

Eksempel: hjælpsom, kreativ, klog og meget venlig.
"
LLM_TITLE_INVALID="Open Voice OS Installation - Ugyldig LLM-konfiguration"
LLM_CONTENT_MISSING_INFO="
Nogle påkrævede LLM-oplysninger mangler.

Angiv API-URL, API-nøgle, model og persona-tekst.
"
LLM_CONTENT_INVALID_URL="
Ugyldig URL.

Angiv en gyldig OpenAI-kompatibel API-URL.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

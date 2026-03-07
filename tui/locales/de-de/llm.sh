#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS Installation - LLM"
LLM_CONTENT_HAVE_DETAILS="
Sie haben die LLM-Funktion für ovos-persona ausgewählt.

Bitte geben Sie Folgendes an:
  - OpenAI-kompatible API-URL
  - API-Schlüssel
  - Persona-Prompt
"
LLM_TITLE_EXISTING="Open Voice OS Installation - Bestehende LLM-Einstellungen"
LLM_CONTENT_EXISTING="
Es wurde eine bestehende LLM-Persona-Konfiguration gefunden.

API-URL: __URL__

Möchten Sie die bestehende Konfiguration beibehalten?
"
LLM_TITLE_URL="Open Voice OS Installation - LLM API-URL"
LLM_CONTENT_URL="
Bitte geben Sie Ihre OpenAI-kompatible API-URL ein.

Beispiel: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Open Voice OS Installation - LLM API-Schlüssel"
LLM_CONTENT_KEY="
Bitte geben Sie Ihren LLM-API-Schlüssel ein.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Leer lassen, um den vorhandenen Schlüssel beizubehalten.
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM Model"
LLM_CONTENT_MODEL="
Please enter the LLM model name to use.

Example: gpt-4o-mini
"
LLM_TITLE_PERSONA="Open Voice OS Installation - LLM Persona"
LLM_CONTENT_PERSONA="
Bitte geben Sie den von ovos-persona verwendeten Persona-Prompt ein.

Beispiel: hilfreich, kreativ, clever und sehr freundlich.
"
LLM_TITLE_INVALID="Open Voice OS Installation - Ungültige LLM-Konfiguration"
LLM_CONTENT_MISSING_INFO="
Einige erforderliche LLM-Informationen fehlen.

Bitte geben Sie API-URL, API-Schlüssel und Persona-Text an.
"
LLM_CONTENT_INVALID_URL="
Ungültige URL.

Bitte geben Sie eine gültige OpenAI-kompatible API-URL an.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

#!/usr/bin/env bash
LLM_TITLE_SETUP="Instal·lació d'Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Heu seleccionat la funció LLM per a ovos-persona.

Si us plau, proporcioneu:
  - URL d'API compatible amb OpenAI
  - Clau d'API
  - Prompt de persona
"
LLM_TITLE_EXISTING="Instal·lació d'Open Voice OS - Configuració LLM existent"
LLM_CONTENT_EXISTING="
S'ha detectat una configuració de persona LLM existent.

URL de l'API: __URL__

Voleu mantenir la configuració existent?
"
LLM_TITLE_URL="Instal·lació d'Open Voice OS - URL de l'API LLM"
LLM_CONTENT_URL="
Introduïu la vostra URL d'API compatible amb OpenAI.

Exemple: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Instal·lació d'Open Voice OS - Clau API LLM"
LLM_CONTENT_KEY="
Introduïu la vostra clau API de l'LLM.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Deixeu-ho en blanc per mantenir la clau existent.
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM Model"
LLM_CONTENT_MODEL="
Please enter the LLM model name to use.

Example: gpt-4o-mini
"
LLM_TITLE_PERSONA="Instal·lació d'Open Voice OS - Persona LLM"
LLM_CONTENT_PERSONA="
Introduïu el prompt de persona utilitzat per ovos-persona.

Exemple: útil, creativa, intel·ligent i molt amable.
"
LLM_TITLE_INVALID="Instal·lació d'Open Voice OS - Configuració LLM no vàlida"
LLM_CONTENT_MISSING_INFO="
Falta informació LLM requerida.

Proporcioneu URL API, clau API i text de persona.
"
LLM_CONTENT_INVALID_URL="
URL no vàlida.

Proporcioneu una URL d'API compatible amb OpenAI vàlida.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

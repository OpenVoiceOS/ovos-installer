#!/usr/bin/env bash
LLM_TITLE_SETUP="Installazione di Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Hai selezionato la funzionalità LLM per ovos-persona.

Per favore fornisci:
  - URL API compatibile con OpenAI
  - Chiave API
  - Modello
  - Prompt della persona
"
LLM_TITLE_EXISTING="Installazione di Open Voice OS - Configurazione LLM esistente"
LLM_CONTENT_EXISTING="
È stata rilevata una configurazione persona LLM esistente.

URL API: __URL__

Vuoi mantenere la configurazione esistente?
"
LLM_TITLE_URL="Installazione di Open Voice OS - URL API LLM"
LLM_CONTENT_URL="
Inserisci il tuo URL API compatibile con OpenAI.

Esempio: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Installazione di Open Voice OS - Chiave API LLM"
LLM_CONTENT_KEY="
Inserisci la tua chiave API LLM.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Lascia vuoto per mantenere la chiave esistente.
"
LLM_TITLE_MODEL="Installazione di Open Voice OS - Modello LLM"
LLM_CONTENT_MODEL="
Inserisci il nome del modello LLM da usare.

Esempio: gpt-4o-mini
"
LLM_TITLE_PERSONA="Installazione di Open Voice OS - Persona LLM"
LLM_CONTENT_PERSONA="
Inserisci il prompt della persona usato da ovos-persona.

Esempio: utile, creativa, brillante e molto amichevole.
"
LLM_TITLE_INVALID="Installazione di Open Voice OS - Configurazione LLM non valida"
LLM_CONTENT_MISSING_INFO="
Mancano alcune informazioni LLM obbligatorie.

Fornisci URL API, chiave API, modello e testo della persona.
"
LLM_CONTENT_INVALID_URL="
URL non valido.

Fornisci un URL API compatibile con OpenAI valido.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

#!/usr/bin/env bash
LLM_TITLE_SETUP="Instalacja Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Wybrano funkcję LLM dla ovos-persona.

Podaj proszę:
  - URL API kompatybilny z OpenAI
  - Klucz API
  - Prompt persony
"
LLM_TITLE_EXISTING="Instalacja Open Voice OS - Istniejące ustawienia LLM"
LLM_CONTENT_EXISTING="
Wykryto istniejącą konfigurację persony LLM.

URL API: __URL__

Czy chcesz zachować istniejącą konfigurację?
"
LLM_TITLE_URL="Instalacja Open Voice OS - URL API LLM"
LLM_CONTENT_URL="
Wprowadź URL API kompatybilny z OpenAI.

Przykład: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Instalacja Open Voice OS - Klucz API LLM"
LLM_CONTENT_KEY="
Wprowadź klucz API LLM.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Pozostaw puste, aby zachować istniejący klucz.
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM Model"
LLM_CONTENT_MODEL="
Please enter the LLM model name to use.

Example: gpt-4o-mini
"
LLM_TITLE_PERSONA="Instalacja Open Voice OS - Persona LLM"
LLM_CONTENT_PERSONA="
Wprowadź prompt persony używany przez ovos-persona.

Przykład: pomocna, kreatywna, sprytna i bardzo przyjazna.
"
LLM_TITLE_INVALID="Instalacja Open Voice OS - Nieprawidłowa konfiguracja LLM"
LLM_CONTENT_MISSING_INFO="
Brakuje wymaganych informacji LLM.

Podaj URL API, klucz API i tekst persony.
"
LLM_CONTENT_INVALID_URL="
Nieprawidłowy URL.

Podaj prawidłowy URL API kompatybilny z OpenAI.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

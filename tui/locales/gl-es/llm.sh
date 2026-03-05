#!/usr/bin/env bash
LLM_TITLE_SETUP="Instalación de Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Seleccionaches a funcionalidade LLM para ovos-persona.

Por favor, fornece:
  - URL de API compatible con OpenAI
  - Chave da API
  - Prompt de persoa
"
LLM_TITLE_EXISTING="Instalación de Open Voice OS - Configuración LLM existente"
LLM_CONTENT_EXISTING="
Detectouse unha configuración de persoa LLM existente.

URL da API: __URL__

Queres manter a configuración existente?
"
LLM_TITLE_URL="Instalación de Open Voice OS - URL da API LLM"
LLM_CONTENT_URL="
Introduce a túa URL de API compatible con OpenAI.

Exemplo: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Instalación de Open Voice OS - Chave da API LLM"
LLM_CONTENT_KEY="
Introduce a túa chave da API LLM.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Déixao baleiro para manter a chave existente.
"
LLM_TITLE_PERSONA="Instalación de Open Voice OS - Persoa LLM"
LLM_CONTENT_PERSONA="
Introduce o prompt de persoa usado por ovos-persona.

Exemplo: útil, creativa, intelixente e moi amigable.
"
LLM_TITLE_INVALID="Instalación de Open Voice OS - Configuración LLM non válida"
LLM_CONTENT_MISSING_INFO="
Falta información LLM requirida.

Fornece URL da API, chave da API e texto de persoa.
"
LLM_CONTENT_INVALID_URL="
URL non válida.

Fornece unha URL de API compatible con OpenAI válida.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

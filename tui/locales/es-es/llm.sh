#!/usr/bin/env bash
LLM_TITLE_SETUP="Instalación de Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Has seleccionado la función LLM para ovos-persona.

Por favor, proporciona:
  - URL de API compatible con OpenAI
  - Clave API
  - Modelo
  - Prompt de persona
"
LLM_TITLE_EXISTING="Instalación de Open Voice OS - Configuración LLM existente"
LLM_CONTENT_EXISTING="
Se detectó una configuración de persona LLM existente.

URL de API: __URL__

¿Quieres conservar la configuración existente?
"
LLM_TITLE_URL="Instalación de Open Voice OS - URL de API LLM"
LLM_CONTENT_URL="
Introduce tu URL de API compatible con OpenAI.

Ejemplo: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Instalación de Open Voice OS - Clave API LLM"
LLM_CONTENT_KEY="
Introduce tu clave API de LLM.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Déjalo vacío para conservar tu clave actual.
"
LLM_TITLE_MODEL="Instalación de Open Voice OS - Modelo LLM"
LLM_CONTENT_MODEL="
Introduce el nombre del modelo LLM que se debe usar.

Ejemplo: gpt-4o-mini
"
LLM_TITLE_PERSONA="Instalación de Open Voice OS - Persona LLM"
LLM_CONTENT_PERSONA="
Introduce el prompt de persona usado por ovos-persona.

Ejemplo: útil, creativa, ingeniosa y muy amable.
"
LLM_TITLE_INVALID="Instalación de Open Voice OS - Configuración LLM no válida"
LLM_CONTENT_MISSING_INFO="
Falta información requerida de LLM.

Proporciona URL de API, clave API, modelo y texto de persona.
"
LLM_CONTENT_INVALID_URL="
URL no válida.

Proporciona una URL de API compatible con OpenAI válida.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

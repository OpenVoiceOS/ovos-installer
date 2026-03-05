#!/usr/bin/env bash
LLM_TITLE_SETUP="Instalação do Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Selecionou a funcionalidade LLM para o ovos-persona.

Por favor, forneça:
  - URL da API compatível com OpenAI
  - Chave da API
  - Prompt de persona
"
LLM_TITLE_EXISTING="Instalação do Open Voice OS - Configuração LLM existente"
LLM_CONTENT_EXISTING="
Foi detetada uma configuração de persona LLM existente.

URL da API: __URL__

Pretende manter a configuração existente?
"
LLM_TITLE_URL="Instalação do Open Voice OS - URL da API LLM"
LLM_CONTENT_URL="
Introduza o seu URL da API compatível com OpenAI.

Exemplo: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Instalação do Open Voice OS - Chave da API LLM"
LLM_CONTENT_KEY="
Introduza a sua chave da API LLM.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Deixe em branco para manter a chave existente.
"
LLM_TITLE_PERSONA="Instalação do Open Voice OS - Persona LLM"
LLM_CONTENT_PERSONA="
Introduza o prompt de persona utilizado pelo ovos-persona.

Exemplo: prestável, criativa, inteligente e muito amigável.
"
LLM_TITLE_INVALID="Instalação do Open Voice OS - Configuração LLM inválida"
LLM_CONTENT_MISSING_INFO="
Falta informação LLM obrigatória.

Forneça URL da API, chave da API e texto da persona.
"
LLM_CONTENT_INVALID_URL="
URL inválido.

Forneça um URL da API compatível com OpenAI válido.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

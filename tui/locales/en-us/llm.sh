#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS Installation - LLM"
LLM_CONTENT_HAVE_DETAILS="
You selected the LLM feature for ovos-persona.

Please provide:
  - OpenAI-compatible API URL
  - API key
  - Model
  - Persona prompt
"
LLM_TITLE_EXISTING="Open Voice OS Installation - Existing LLM Settings"
LLM_CONTENT_EXISTING="
Existing LLM persona configuration detected.

API URL: __URL__

Would you like to keep the existing configuration?
"
LLM_TITLE_URL="Open Voice OS Installation - LLM API URL"
LLM_CONTENT_URL="
Please enter your OpenAI-compatible API URL.

Example: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Open Voice OS Installation - LLM API Key"
LLM_CONTENT_KEY="
Please enter your LLM API key.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Leave empty to keep your existing key.
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM Model"
LLM_CONTENT_MODEL="
Please enter the LLM model name to use.

Example: gpt-4o-mini
"
LLM_TITLE_PERSONA="Open Voice OS Installation - LLM Persona"
LLM_CONTENT_PERSONA="
Please enter the persona prompt used by ovos-persona.

Example: helpful, creative, clever, and very friendly.
"
LLM_TITLE_INVALID="Open Voice OS Installation - Invalid LLM Configuration"
LLM_CONTENT_MISSING_INFO="
Some required LLM information is missing.

Please provide API URL, API key, model, and persona text.
"
LLM_CONTENT_INVALID_URL="
Invalid URL.

Please provide a valid OpenAI-compatible API URL.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING
export LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

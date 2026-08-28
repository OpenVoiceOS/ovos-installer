#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS Installation - LLM"
LLM_CONTENT_HAVE_DETAILS="
You selected the LLM feature for ovos-persona.

This lets OVOS use an AI assistant when normal skills do not have a good answer.

You will be asked for:
  - API URL: where OVOS sends AI requests
  - API key: your private access key for that service
  - Model: which AI model to use
  - Assistant style: how the assistant should sound
  - Reply length: how much room the model gets to answer
  - Creativity: lower is safer, higher is more imaginative
  - Focus: lower keeps answers tighter and more predictable

Safe defaults are pre-filled for the advanced options.
"
LLM_TITLE_EXISTING="Open Voice OS Installation - Existing LLM Settings"
LLM_CONTENT_EXISTING="
Existing LLM persona configuration detected.

API URL: __URL__
Model: __MODEL__

Would you like to keep the existing configuration?
"
LLM_TITLE_URL="Open Voice OS Installation - LLM API URL"
LLM_CONTENT_URL="
Enter the OpenAI-compatible API URL used by your provider.

Example: https://llama.smartgic.io/v1

Tip: many compatible servers need the /v1 part.
"
LLM_TITLE_KEY="Open Voice OS Installation - LLM API Key"
LLM_CONTENT_KEY="
Enter the API key for your AI provider.

This is kept private and is not shown in the installer summary.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Leave empty to keep your existing key.
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM Model"
LLM_CONTENT_MODEL="
Enter the model name OVOS should use for conversations.

Examples: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Open Voice OS Installation - LLM Assistant Style"
LLM_DEFAULT_PERSONA="Respond in the same language as the user in a plain spoken style for a voice assistant. No emojis. No markdown. No bullet points. No parenthetical asides. Keep replies concise, usually one or two short sentences. Start directly with the answer and sound natural when spoken aloud."
LLM_CONTENT_PERSONA="
Describe how the assistant should speak and behave.

The default is tuned for short, voice-friendly replies.
Example: Respond in plain spoken English for a voice assistant. No emojis. Keep replies concise.
"
LLM_TITLE_MAX_TOKENS="Open Voice OS Installation - LLM Reply Length"
LLM_CONTENT_MAX_TOKENS="
Choose how much room the model gets for each answer.

Higher numbers allow fuller replies but may be slower.
Lower numbers are shorter and faster.

Recommended for voice use: 300
"
LLM_TITLE_TEMPERATURE="Open Voice OS Installation - LLM Creativity"
LLM_CONTENT_TEMPERATURE="
Choose how creative the replies should be.

Lower values are calmer and more predictable.
Higher values are more playful and varied.

Recommended for voice use: 0.2
"
LLM_TITLE_TOP_P="Open Voice OS Installation - LLM Focus"
LLM_CONTENT_TOP_P="
Choose how tightly the model should stay on the most likely words.

Lower values keep replies more focused and consistent.
Higher values allow more variety.

Recommended for voice use: 0.1
"
LLM_TITLE_INVALID="Open Voice OS Installation - Invalid LLM Configuration"
LLM_CONTENT_MISSING_INFO="
Some required LLM information is missing.

Please provide API URL, API key, model, assistant style, and the tuning values.
"
LLM_CONTENT_INVALID_URL="
Invalid URL.

Please provide a valid OpenAI-compatible API URL.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Invalid reply length.

Please enter a whole number greater than 0.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Invalid creativity level.

Please enter a number between 0 and 2.
"
LLM_CONTENT_INVALID_TOP_P="
Invalid focus level.

Please enter a number between 0 and 1.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING
export LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_DEFAULT_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_MAX_TOKENS LLM_CONTENT_MAX_TOKENS
export LLM_TITLE_TEMPERATURE LLM_CONTENT_TEMPERATURE
export LLM_TITLE_TOP_P LLM_CONTENT_TOP_P
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL
export LLM_CONTENT_INVALID_MAX_TOKENS LLM_CONTENT_INVALID_TEMPERATURE LLM_CONTENT_INVALID_TOP_P

#!/usr/bin/env bash
CONTENT="
Quase a terminar. Um breve resumo:

    - Implementação:  ${METHOD:-}
    - Versão:         ${CHANNEL:-}
    - Perfil:         ${PROFILE:-}
    - Skills:         ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Skills extra:   ${FEATURE_EXTRA_SKILLS_SUMMARY_STATE:-}
    - Home Assistant: ${HOMEASSISTANT_SUMMARY_STATE:-}
    - LLM:            ${LLM_SUMMARY_STATE:-}
    - Voz:            ${SPEECH_SUMMARY_STATE:-}
    - Otimização:     ${TUNING_SUMMARY_STATE:-}

As decisões tomadas durante o processo de instalação do Open Voice OS foram cuidadosamente consideradas para personalizar o nosso sistema de acordo com as suas necessidades e preferências individuais.

As definições estão correctas? Se não, seleccione ${BACK_BUTTON:-} para voltar atrás e fazer alterações.
"
TITLE="Open Voice OS Instalação - Resumo"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"
SUMMARY_SPEECH_LOCAL="nesta máquina"
SUMMARY_SPEECH_PUBLIC="servidores públicos"
SUMMARY_SPEECH_PUBLIC_HARDWARE="servidores públicos (local: Pi 5 com 8 GB ou melhor)"
SUMMARY_SPEECH_PUBLIC_SETUP="servidores públicos (local indisponível aqui)"
SUMMARY_SPEECH_UNUSED="não utilizado por este perfil"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION SUMMARY_SPEECH_LOCAL SUMMARY_SPEECH_PUBLIC SUMMARY_SPEECH_PUBLIC_HARDWARE SUMMARY_SPEECH_PUBLIC_SETUP SUMMARY_SPEECH_UNUSED

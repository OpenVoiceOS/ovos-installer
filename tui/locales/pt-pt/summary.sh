#!/usr/bin/env bash
CONTENT="
Quase a terminar. Um breve resumo:

    - Implementação: ${METHOD:-}
    - Versão:      ${CHANNEL:-}
    - Perfil:      ${PROFILE:-}
    - Skills:      ${FEATURE_SKILLS_SUMMARY_STATE:-}
    - Otimização:  ${TUNING_SUMMARY_STATE:-}

As decisões tomadas durante o processo de instalação do Open Voice OS foram cuidadosamente consideradas para personalizar o nosso sistema de acordo com as suas necessidades e preferências individuais.

As definições estão correctas? Se não, seleccione ${BACK_BUTTON:-} (ou prima ESC) para voltar atrás e fazer alterações.
"
TITLE="Open Voice OS Instalação - Resumo"

SUMMARY_STATE_ENABLED="enabled"
SUMMARY_STATE_DISABLED="disabled"
SUMMARY_STATE_UNSUPPORTED_PROFILE="selected (not supported for this profile)"
SUMMARY_STATE_MISSING_URL="selected (missing URL; will be skipped)"
SUMMARY_STATE_MISSING_CONFIGURATION="selected (missing configuration; will be skipped)"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION

#!/usr/bin/env bash
CONTENT="
As habilidades permiten a interacción por voz, facéndoo eficiente para tarefas coma a automatización do fogar (domótica), a recuperación de información e o control de dispositivos intelixentes mediante comandos en linguaxe natural.

Escolle as funcionalidades que queres activar:
"
TITLE="Instalación de Open Voice OS - Funcionalidades"
SKILL_DESCRIPTION="Cargar as habilidades predeterminadas de OVOS"
EXTRA_SKILL_DESCRIPTION="Cargar habilidades adicionais de OVOS"
HOMEASSISTANT_DESCRIPTION="Activar a integración con Home Assistant (require URL e token)"
LLM_DESCRIPTION="Activar o modo de conversa con IA para OVOS Persona (configuración guiada de URL, chave, modelo, estilo e axuste de respostas)"

export CONTENT TITLE SKILL_DESCRIPTION EXTRA_SKILL_DESCRIPTION HOMEASSISTANT_DESCRIPTION LLM_DESCRIPTION

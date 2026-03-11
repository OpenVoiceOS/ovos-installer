#!/usr/bin/env bash
CONTENT="
Skills enable interaction through speech, making it efficient for tasks like home automation, information retrieval, and controlling smart devices using natural language commands.

Please choose the features to enable:
"
TITLE="Open Voice OS Installation - Features"
SKILL_DESCRIPTION="Load default OVOS skills"
EXTRA_SKILL_DESCRIPTION="Load extra OVOS skills"
GUI_DESCRIPTION="Enable OVOS GUI (Mark II/DevKit on Debian Trixie)"
HOMEASSISTANT_DESCRIPTION="Enable Home Assistant integration"
LLM_DESCRIPTION="Enable AI fallback for OVOS Persona (guided setup)"

export CONTENT TITLE SKILL_DESCRIPTION EXTRA_SKILL_DESCRIPTION GUI_DESCRIPTION HOMEASSISTANT_DESCRIPTION LLM_DESCRIPTION

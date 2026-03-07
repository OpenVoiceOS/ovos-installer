#!/usr/bin/env bash
CONTENT="
Les compétences permettent le déclenchement d'actions par la parole, ce qui rend des tâches telles que la domotique, les nouvelles, la météo, etc. simples et intuitives.

Veuillez sélectionner les fonctionnalités à activer :
"
TITLE="Open Voice OS Installation - Fonctionnalités"
SKILL_DESCRIPTION="Chargement des compétences par défaut d'OVOS"
EXTRA_SKILL_DESCRIPTION="Chargement des compétences OVOS supplémentaires"
HOMEASSISTANT_DESCRIPTION="Activer l'intégration Home Assistant (nécessite une URL et un jeton)"
LLM_DESCRIPTION="Activer le secours conversationnel par IA pour OVOS Persona (configuration guidée de l'URL, de la clé, du modèle, du style et du réglage des réponses)"

export CONTENT TITLE SKILL_DESCRIPTION EXTRA_SKILL_DESCRIPTION HOMEASSISTANT_DESCRIPTION LLM_DESCRIPTION

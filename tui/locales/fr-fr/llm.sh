#!/usr/bin/env bash
LLM_TITLE_SETUP="Installation d'Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Vous avez sélectionné la fonctionnalité LLM pour ovos-persona.

Veuillez fournir :
  - URL API compatible OpenAI
  - Clé API
  - Modèle
  - Prompt de persona
"
LLM_TITLE_EXISTING="Installation d'Open Voice OS - Configuration LLM existante"
LLM_CONTENT_EXISTING="
Une configuration de persona LLM existante a été détectée.

URL API : __URL__

Souhaitez-vous conserver la configuration existante ?
"
LLM_TITLE_URL="Installation d'Open Voice OS - URL API LLM"
LLM_CONTENT_URL="
Veuillez saisir votre URL API compatible OpenAI.

Exemple : https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Installation d'Open Voice OS - Clé API LLM"
LLM_CONTENT_KEY="
Veuillez saisir votre clé API LLM.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Laissez vide pour conserver votre clé existante.
"
LLM_TITLE_MODEL="Installation d'Open Voice OS - Modèle LLM"
LLM_CONTENT_MODEL="
Veuillez saisir le nom du modèle LLM à utiliser.

Exemple : gpt-4o-mini
"
LLM_TITLE_PERSONA="Installation d'Open Voice OS - Persona LLM"
LLM_CONTENT_PERSONA="
Veuillez saisir le prompt de persona utilisé par ovos-persona.

Exemple : serviable, créatif, malin et très amical.
"
LLM_TITLE_INVALID="Installation d'Open Voice OS - Configuration LLM invalide"
LLM_CONTENT_MISSING_INFO="
Certaines informations LLM requises sont manquantes.

Veuillez fournir l'URL API, la clé API, le modèle et le texte de persona.
"
LLM_CONTENT_INVALID_URL="
URL invalide.

Veuillez fournir une URL API compatible OpenAI valide.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

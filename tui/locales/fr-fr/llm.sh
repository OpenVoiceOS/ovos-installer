#!/usr/bin/env bash
LLM_TITLE_SETUP="Installation d'Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Vous avez sélectionné la fonctionnalité LLM pour ovos-persona.

Cela permet à OVOS d'utiliser un assistant IA lorsque les compétences habituelles n'ont pas de bonne réponse.

Les informations demandées seront :
  - URL API : où OVOS envoie les requêtes IA
  - Clé API : votre clé d'accès privée à ce service
  - Modèle : quel modèle d'IA utiliser
  - Style de l'assistant : comment l'assistant doit s'exprimer
  - Longueur de réponse : quelle marge le modèle a pour répondre
  - Créativité : des valeurs basses sont plus sûres, des valeurs hautes plus imaginatives
  - Focalisation : des valeurs basses gardent des réponses plus serrées et prévisibles

Des valeurs sûres sont déjà préremplies pour les options avancées.
"
LLM_TITLE_EXISTING="Installation d'Open Voice OS - Configuration LLM existante"
LLM_CONTENT_EXISTING="
Une configuration de persona LLM existante a été détectée.

URL API : __URL__
Modèle : __MODEL__

Souhaitez-vous conserver la configuration existante ?
"
LLM_TITLE_URL="Installation d'Open Voice OS - URL API LLM"
LLM_CONTENT_URL="
Veuillez saisir l'URL API compatible OpenAI utilisée par votre fournisseur.

Exemple : https://llama.smartgic.io/v1

Astuce : beaucoup de serveurs compatibles ont besoin de la partie /v1.
"
LLM_TITLE_KEY="Installation d'Open Voice OS - Clé API LLM"
LLM_CONTENT_KEY="
Veuillez saisir la clé API de votre fournisseur d'IA.

Elle reste privée et n'apparaît pas dans le résumé de l'installation.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Laissez vide pour conserver votre clé existante.
"
LLM_TITLE_MODEL="Installation d'Open Voice OS - Modèle LLM"
LLM_CONTENT_MODEL="
Veuillez saisir le nom du modèle qu'OVOS doit utiliser pour les conversations.

Exemples : gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Installation d'Open Voice OS - Style de l'assistant LLM"
LLM_DEFAULT_PERSONA="Répondez dans la langue de l'utilisateur, dans un style oral simple et naturel pour un assistant vocal. Pas d'emojis. Pas de markdown. Pas de puces. Pas d'incises entre parenthèses. Gardez des réponses concises, généralement une ou deux phrases courtes. Commencez directement par la réponse et faites en sorte qu'elle sonne naturellement à l'oral."
LLM_CONTENT_PERSONA="
Décrivez comment l'assistant doit parler et se comporter.

La valeur par défaut est réglée pour des réponses courtes et adaptées à la voix.
Exemple : Répondez en français simple pour un assistant vocal. Sans emoji. Réponses courtes.
"
LLM_TITLE_MAX_TOKENS="Installation d'Open Voice OS - Longueur de réponse LLM"
LLM_CONTENT_MAX_TOKENS="
Choisissez la marge dont le modèle dispose pour chaque réponse.

Des valeurs plus élevées permettent des réponses plus complètes, mais peuvent être plus lentes.
Des valeurs plus basses donnent des réponses plus courtes et plus rapides.

Recommandé pour un usage vocal : 300
"
LLM_TITLE_TEMPERATURE="Installation d'Open Voice OS - Créativité LLM"
LLM_CONTENT_TEMPERATURE="
Choisissez à quel point les réponses doivent être créatives.

Des valeurs basses sont plus calmes et prévisibles.
Des valeurs hautes sont plus variées et plus libres.

Recommandé pour un usage vocal : 0.2
"
LLM_TITLE_TOP_P="Installation d'Open Voice OS - Focalisation LLM"
LLM_CONTENT_TOP_P="
Choisissez à quel point le modèle doit rester sur les mots les plus probables.

Des valeurs basses rendent les réponses plus cohérentes et plus ciblées.
Des valeurs hautes autorisent davantage de variété.

Recommandé pour un usage vocal : 0.1
"
LLM_TITLE_INVALID="Installation d'Open Voice OS - Configuration LLM invalide"
LLM_CONTENT_MISSING_INFO="
Certaines informations LLM requises sont manquantes.

Veuillez fournir l'URL API, la clé API, le modèle, le style de l'assistant et les valeurs de réglage.
"
LLM_CONTENT_INVALID_URL="
URL invalide.

Veuillez fournir une URL API compatible OpenAI valide.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Longueur de réponse invalide.

Veuillez saisir un nombre entier supérieur à 0.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Niveau de créativité invalide.

Veuillez saisir un nombre entre 0 et 2.
"
LLM_CONTENT_INVALID_TOP_P="
Niveau de focalisation invalide.

Veuillez saisir un nombre entre 0 et 1.
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

#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS Installatie - LLM"
LLM_CONTENT_HAVE_DETAILS="
Je hebt de LLM-functie voor ovos-persona geselecteerd.

Hiermee kan OVOS een AI-assistent gebruiken wanneer normale skills geen goed antwoord hebben.

Je wordt gevraagd om:
  - API-URL: waar OVOS AI-verzoeken naartoe stuurt
  - API-sleutel: je privésleutel voor toegang tot die dienst
  - Model: welk AI-model gebruikt moet worden
  - Assistentstijl: hoe de assistent moet klinken
  - Antwoordlengte: hoeveel ruimte het model krijgt om te antwoorden
  - Creativiteit: lagere waarden zijn veiliger, hogere waarden fantasievoller
  - Focus: lagere waarden houden antwoorden strakker en voorspelbaarder

Voor de geavanceerde opties zijn al veilige standaardwaarden ingevuld.
"
LLM_TITLE_EXISTING="Open Voice OS Installatie - Bestaande LLM-instellingen"
LLM_CONTENT_EXISTING="
Bestaande LLM persona-configuratie gevonden.

API-URL: __URL__
Model: __MODEL__

Wil je de bestaande configuratie behouden?
"
LLM_TITLE_URL="Open Voice OS Installatie - LLM API-URL"
LLM_CONTENT_URL="
Voer de OpenAI-compatibele API-URL van je provider in.

Voorbeeld: https://llama.smartgic.io/v1

Tip: veel compatibele servers hebben het deel /v1 nodig.
"
LLM_TITLE_KEY="Open Voice OS Installatie - LLM API-sleutel"
LLM_CONTENT_KEY="
Voer de API-sleutel van je AI-provider in.

Die blijft privé en wordt niet getoond in het installatieoverzicht.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Laat leeg om je bestaande sleutel te behouden.
"
LLM_TITLE_MODEL="Open Voice OS Installatie - LLM-model"
LLM_CONTENT_MODEL="
Voer de modelnaam in die OVOS voor gesprekken moet gebruiken.

Voorbeelden: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Open Voice OS Installatie - LLM assistentstijl"
LLM_CONTENT_PERSONA="
Beschrijf hoe de assistent moet praten en zich moet gedragen.

De standaardinstelling is afgestemd op korte, spraakvriendelijke antwoorden.
Voorbeeld: Antwoord in eenvoudig Nederlands voor een spraakassistent. Geen emoji. Houd antwoorden kort.
"
LLM_TITLE_MAX_TOKENS="Open Voice OS Installatie - LLM antwoordlengte"
LLM_CONTENT_MAX_TOKENS="
Kies hoeveel ruimte het model voor elk antwoord krijgt.

Hogere waarden geven vollere antwoorden, maar kunnen trager zijn.
Lagere waarden zijn korter en sneller.

Aanbevolen voor spraakgebruik: 300
"
LLM_TITLE_TEMPERATURE="Open Voice OS Installatie - LLM creativiteit"
LLM_CONTENT_TEMPERATURE="
Kies hoe creatief de antwoorden moeten zijn.

Lagere waarden zijn rustiger en voorspelbaarder.
Hogere waarden zijn speelser en gevarieerder.

Aanbevolen voor spraakgebruik: 0.2
"
LLM_TITLE_TOP_P="Open Voice OS Installatie - LLM focus"
LLM_CONTENT_TOP_P="
Kies hoe sterk het model bij de meest waarschijnlijke woorden moet blijven.

Lagere waarden maken antwoorden consistenter en gerichter.
Hogere waarden laten meer variatie toe.

Aanbevolen voor spraakgebruik: 0.1
"
LLM_TITLE_INVALID="Open Voice OS Installatie - Ongeldige LLM-configuratie"
LLM_CONTENT_MISSING_INFO="
Sommige vereiste LLM-informatie ontbreekt.

Geef API-URL, API-sleutel, model, assistentstijl en afstelwaarden op.
"
LLM_CONTENT_INVALID_URL="
Ongeldige URL.

Geef een geldige OpenAI-compatibele API-URL op.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Ongeldige antwoordlengte.

Voer een geheel getal groter dan 0 in.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Ongeldig creativiteitsniveau.

Voer een getal tussen 0 en 2 in.
"
LLM_CONTENT_INVALID_TOP_P="
Ongeldig focusniveau.

Voer een getal tussen 0 en 1 in.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING
export LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_MAX_TOKENS LLM_CONTENT_MAX_TOKENS
export LLM_TITLE_TEMPERATURE LLM_CONTENT_TEMPERATURE
export LLM_TITLE_TOP_P LLM_CONTENT_TOP_P
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL
export LLM_CONTENT_INVALID_MAX_TOKENS LLM_CONTENT_INVALID_TEMPERATURE LLM_CONTENT_INVALID_TOP_P

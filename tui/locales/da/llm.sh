#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS Installation - LLM"
LLM_CONTENT_HAVE_DETAILS="
Du har valgt LLM-funktionen til ovos-persona.

Det gør det muligt for OVOS at bruge en AI-assistent, når normale skills ikke har et godt svar.

Du bliver bedt om:
  - API-URL: hvor OVOS sender AI-forespørgsler
  - API-nøgle: din private adgangsnøgle til tjenesten
  - Model: hvilken AI-model der skal bruges
  - Assistentstil: hvordan assistenten skal lyde
  - Svarlængde: hvor meget plads modellen får til at svare
  - Kreativitet: lavere værdier er sikrere, højere er mere fantasifulde
  - Fokus: lavere værdier holder svarene strammere og mere forudsigelige

Sikre standardværdier er allerede udfyldt for de avancerede valg.
"
LLM_TITLE_EXISTING="Open Voice OS Installation - Eksisterende LLM-indstillinger"
LLM_CONTENT_EXISTING="
Eksisterende LLM persona-konfiguration fundet.

API-URL: __URL__
Model: __MODEL__

Vil du beholde den eksisterende konfiguration?
"
LLM_TITLE_URL="Open Voice OS Installation - LLM API-URL"
LLM_CONTENT_URL="
Indtast den OpenAI-kompatible API-URL, som din udbyder bruger.

Eksempel: https://llama.smartgic.io/v1

Tip: mange kompatible servere kræver delen /v1.
"
LLM_TITLE_KEY="Open Voice OS Installation - LLM API-nøgle"
LLM_CONTENT_KEY="
Indtast API-nøglen til din AI-udbyder.

Den holdes privat og vises ikke i installationsoversigten.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Lad feltet være tomt for at beholde din eksisterende nøgle.
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM-model"
LLM_CONTENT_MODEL="
Indtast modelnavnet, som OVOS skal bruge til samtaler.

Eksempler: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Open Voice OS Installation - LLM assistentstil"
LLM_CONTENT_PERSONA="
Beskriv hvordan assistenten skal tale og opføre sig.

Standardvalget er justeret til korte, stemmevenlige svar.
Eksempel: Svar i almindeligt dansk til en stemmeassistent. Ingen emojis. Hold svarene korte.
"
LLM_TITLE_MAX_TOKENS="Open Voice OS Installation - LLM svarlængde"
LLM_CONTENT_MAX_TOKENS="
Vælg hvor meget plads modellen får til hvert svar.

Højere værdier giver fyldigere svar, men kan være langsommere.
Lavere værdier giver kortere og hurtigere svar.

Anbefalet til stemmebrug: 300
"
LLM_TITLE_TEMPERATURE="Open Voice OS Installation - LLM kreativitet"
LLM_CONTENT_TEMPERATURE="
Vælg hvor kreative svarene skal være.

Lavere værdier er roligere og mere forudsigelige.
Højere værdier er mere legende og varierede.

Anbefalet til stemmebrug: 0.2
"
LLM_TITLE_TOP_P="Open Voice OS Installation - LLM fokus"
LLM_CONTENT_TOP_P="
Vælg hvor tæt modellen skal holde sig til de mest sandsynlige ord.

Lavere værdier gør svarene mere fokuserede og ensartede.
Højere værdier giver mere variation.

Anbefalet til stemmebrug: 0.1
"
LLM_TITLE_INVALID="Open Voice OS Installation - Ugyldig LLM-konfiguration"
LLM_CONTENT_MISSING_INFO="
Nogle påkrævede LLM-oplysninger mangler.

Angiv API-URL, API-nøgle, model, assistentstil og justeringsværdier.
"
LLM_CONTENT_INVALID_URL="
Ugyldig URL.

Angiv en gyldig OpenAI-kompatibel API-URL.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Ugyldig svarlængde.

Indtast et helt tal større end 0.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Ugyldigt kreativitetsniveau.

Indtast et tal mellem 0 og 2.
"
LLM_CONTENT_INVALID_TOP_P="
Ugyldigt fokusniveau.

Indtast et tal mellem 0 og 1.
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

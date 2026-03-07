#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS instalazioa - LLM"
LLM_CONTENT_HAVE_DETAILS="
ovos-persona-rako LLM funtzioa hautatu duzu.

Mesedez, eman:
  - OpenAI bateragarria den API URLa
  - API gakoa
  - Pertsona prompt-a
"
LLM_TITLE_EXISTING="Open Voice OS instalazioa - Dagoen LLM konfigurazioa"
LLM_CONTENT_EXISTING="
Lehendik dagoen LLM pertsona konfigurazioa aurkitu da.

API URLa: __URL__

Lehendik dagoen konfigurazioa mantendu nahi duzu?
"
LLM_TITLE_URL="Open Voice OS instalazioa - LLM API URLa"
LLM_CONTENT_URL="
Sartu zure OpenAI bateragarria den API URLa.

Adibidea: https://llama.smartgic.io/v1
"
LLM_TITLE_KEY="Open Voice OS instalazioa - LLM API gakoa"
LLM_CONTENT_KEY="
Sartu zure LLM API gakoa.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Utzi hutsik lehendik duzun gakoa mantentzeko.
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM Model"
LLM_CONTENT_MODEL="
Please enter the LLM model name to use.

Example: gpt-4o-mini
"
LLM_TITLE_PERSONA="Open Voice OS instalazioa - LLM pertsona"
LLM_CONTENT_PERSONA="
Sartu ovos-personak erabiltzen duen pertsona prompt-a.

Adibidea: lagungarria, sortzailea, azkarra eta oso atsegina.
"
LLM_TITLE_INVALID="Open Voice OS instalazioa - LLM konfigurazio baliogabea"
LLM_CONTENT_MISSING_INFO="
Beharrezko LLM informazio batzuk falta dira.

Eman API URLa, API gakoa eta pertsona testua.
"
LLM_CONTENT_INVALID_URL="
URL baliogabea.

Eman OpenAI bateragarria den API URL baliodun bat.
"

export LLM_TITLE_SETUP LLM_CONTENT_HAVE_DETAILS
export LLM_TITLE_EXISTING LLM_CONTENT_EXISTING
export LLM_TITLE_URL LLM_CONTENT_URL
export LLM_TITLE_KEY LLM_CONTENT_KEY LLM_CONTENT_KEY_KEEP_EXISTING LLM_TITLE_MODEL LLM_CONTENT_MODEL
export LLM_TITLE_PERSONA LLM_CONTENT_PERSONA
export LLM_TITLE_INVALID LLM_CONTENT_MISSING_INFO LLM_CONTENT_INVALID_URL

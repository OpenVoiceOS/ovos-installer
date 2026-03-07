#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS Installation - LLM"
LLM_CONTENT_HAVE_DETAILS="
Sie haben die LLM-Funktion für ovos-persona ausgewählt.

Damit kann OVOS einen KI-Assistenten verwenden, wenn normale Skills keine gute Antwort haben.

Sie werden nach Folgendem gefragt:
  - API-URL: wohin OVOS die KI-Anfragen sendet
  - API-Schlüssel: Ihr privater Zugriffsschlüssel für diesen Dienst
  - Modell: welches KI-Modell verwendet werden soll
  - Assistentenstil: wie der Assistent klingen soll
  - Antwortlänge: wie viel Spielraum das Modell für Antworten bekommt
  - Kreativität: niedrigere Werte sind sicherer, höhere fantasievoller
  - Fokus: niedrigere Werte halten Antworten knapper und vorhersehbarer

Für die erweiterten Optionen sind bereits sinnvolle Standardwerte eingetragen.
"
LLM_TITLE_EXISTING="Open Voice OS Installation - Bestehende LLM-Einstellungen"
LLM_CONTENT_EXISTING="
Es wurde eine bestehende LLM-Persona-Konfiguration gefunden.

API-URL: __URL__
Modell: __MODEL__

Möchten Sie die bestehende Konfiguration beibehalten?
"
LLM_TITLE_URL="Open Voice OS Installation - LLM API-URL"
LLM_CONTENT_URL="
Bitte geben Sie die OpenAI-kompatible API-URL Ihres Anbieters ein.

Beispiel: https://llama.smartgic.io/v1

Tipp: Viele kompatible Server benötigen den Teil /v1.
"
LLM_TITLE_KEY="Open Voice OS Installation - LLM API-Schlüssel"
LLM_CONTENT_KEY="
Bitte geben Sie den API-Schlüssel Ihres KI-Anbieters ein.

Dieser bleibt privat und wird in der Installationsübersicht nicht angezeigt.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Leer lassen, um den vorhandenen Schlüssel beizubehalten.
"
LLM_TITLE_MODEL="Open Voice OS Installation - LLM-Modell"
LLM_CONTENT_MODEL="
Bitte geben Sie den Modellnamen ein, den OVOS für Gespräche verwenden soll.

Beispiele: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Open Voice OS Installation - LLM-Assistentenstil"
LLM_CONTENT_PERSONA="
Beschreiben Sie, wie der Assistent sprechen und reagieren soll.

Der Standard ist auf kurze, sprachfreundliche Antworten abgestimmt.
Beispiel: Antworte in einfachem Deutsch für einen Sprachassistenten. Keine Emojis. Kurz antworten.
"
LLM_TITLE_MAX_TOKENS="Open Voice OS Installation - LLM-Antwortlänge"
LLM_CONTENT_MAX_TOKENS="
Wählen Sie, wie viel Spielraum das Modell für jede Antwort bekommt.

Höhere Werte erlauben ausführlichere Antworten, können aber langsamer sein.
Niedrigere Werte sind kürzer und schneller.

Empfohlen für Spracheingabe: 300
"
LLM_TITLE_TEMPERATURE="Open Voice OS Installation - LLM-Kreativität"
LLM_CONTENT_TEMPERATURE="
Wählen Sie, wie kreativ die Antworten sein sollen.

Niedrige Werte sind ruhiger und vorhersehbarer.
Hohe Werte sind verspielter und abwechslungsreicher.

Empfohlen für Spracheingabe: 0.2
"
LLM_TITLE_TOP_P="Open Voice OS Installation - LLM-Fokus"
LLM_CONTENT_TOP_P="
Wählen Sie, wie stark das Modell bei den wahrscheinlichsten Wörtern bleiben soll.

Niedrige Werte machen Antworten fokussierter und gleichmäßiger.
Hohe Werte erlauben mehr Vielfalt.

Empfohlen für Spracheingabe: 0.1
"
LLM_TITLE_INVALID="Open Voice OS Installation - Ungültige LLM-Konfiguration"
LLM_CONTENT_MISSING_INFO="
Einige erforderliche LLM-Informationen fehlen.

Bitte geben Sie API-URL, API-Schlüssel, Modell, Assistentenstil und Abstimmungswerte an.
"
LLM_CONTENT_INVALID_URL="
Ungültige URL.

Bitte geben Sie eine gültige OpenAI-kompatible API-URL an.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Ungültige Antwortlänge.

Bitte geben Sie eine ganze Zahl größer als 0 ein.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Ungültiger Kreativitätswert.

Bitte geben Sie eine Zahl zwischen 0 und 2 ein.
"
LLM_CONTENT_INVALID_TOP_P="
Ungültiger Fokuswert.

Bitte geben Sie eine Zahl zwischen 0 und 1 ein.
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

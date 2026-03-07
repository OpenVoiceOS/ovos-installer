#!/usr/bin/env bash
LLM_TITLE_SETUP="Installazione di Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Hai selezionato la funzionalità LLM per ovos-persona.

Questo permette a OVOS di usare un assistente IA quando le skill normali non hanno una buona risposta.

Ti verrà chiesto di inserire:
  - URL API: dove OVOS invia le richieste IA
  - Chiave API: la tua chiave privata di accesso al servizio
  - Modello: quale modello IA usare
  - Stile dell'assistente: come deve parlare l'assistente
  - Lunghezza della risposta: quanto spazio ha il modello per rispondere
  - Creatività: valori più bassi sono più sicuri, valori più alti più fantasiosi
  - Focus: valori più bassi mantengono risposte più strette e prevedibili

Per le opzioni avanzate sono già presenti valori sicuri predefiniti.
"
LLM_TITLE_EXISTING="Installazione di Open Voice OS - Configurazione LLM esistente"
LLM_CONTENT_EXISTING="
È stata rilevata una configurazione persona LLM esistente.

URL API: __URL__
Modello: __MODEL__

Vuoi mantenere la configurazione esistente?
"
LLM_TITLE_URL="Installazione di Open Voice OS - URL API LLM"
LLM_CONTENT_URL="
Inserisci l'URL API compatibile con OpenAI usato dal tuo fornitore.

Esempio: https://llama.smartgic.io/v1

Suggerimento: molti server compatibili richiedono la parte /v1.
"
LLM_TITLE_KEY="Installazione di Open Voice OS - Chiave API LLM"
LLM_CONTENT_KEY="
Inserisci la chiave API del tuo fornitore IA.

Resta privata e non viene mostrata nel riepilogo dell'installazione.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Lascia vuoto per mantenere la chiave esistente.
"
LLM_TITLE_MODEL="Installazione di Open Voice OS - Modello LLM"
LLM_CONTENT_MODEL="
Inserisci il nome del modello che OVOS deve usare per le conversazioni.

Esempi: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Installazione di Open Voice OS - Stile dell'assistente LLM"
LLM_DEFAULT_PERSONA="Rispondi nella lingua dell'utente con uno stile parlato semplice e naturale per un assistente vocale. Niente emoji. Niente markdown. Niente elenchi puntati. Niente inciso tra parentesi. Mantieni le risposte concise, di solito una o due frasi brevi. Inizia direttamente con la risposta e fai in modo che suoni naturale quando viene letta ad alta voce."
LLM_CONTENT_PERSONA="
Descrivi come deve parlare e comportarsi l'assistente.

Il valore predefinito è ottimizzato per risposte brevi e adatte alla voce.
Esempio: Rispondi in italiano semplice per un assistente vocale. Niente emoji. Risposte brevi.
"
LLM_TITLE_MAX_TOKENS="Installazione di Open Voice OS - Lunghezza della risposta LLM"
LLM_CONTENT_MAX_TOKENS="
Scegli quanto spazio ha il modello per ogni risposta.

Valori più alti permettono risposte più complete, ma possono essere più lenti.
Valori più bassi rendono le risposte più brevi e più rapide.

Consigliato per l'uso vocale: 300
"
LLM_TITLE_TEMPERATURE="Installazione di Open Voice OS - Creatività LLM"
LLM_CONTENT_TEMPERATURE="
Scegli quanto devono essere creative le risposte.

I valori bassi sono più calmi e prevedibili.
I valori alti sono più vari e più giocosi.

Consigliato per l'uso vocale: 0.2
"
LLM_TITLE_TOP_P="Installazione di Open Voice OS - Focus LLM"
LLM_CONTENT_TOP_P="
Scegli quanto il modello deve restare sulle parole più probabili.

I valori bassi rendono le risposte più coerenti e focalizzate.
I valori alti permettono maggiore varietà.

Consigliato per l'uso vocale: 0.1
"
LLM_TITLE_INVALID="Installazione di Open Voice OS - Configurazione LLM non valida"
LLM_CONTENT_MISSING_INFO="
Mancano alcune informazioni LLM obbligatorie.

Fornisci URL API, chiave API, modello, stile dell'assistente e valori di regolazione.
"
LLM_CONTENT_INVALID_URL="
URL non valido.

Fornisci un URL API compatibile con OpenAI valido.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Lunghezza della risposta non valida.

Inserisci un numero intero maggiore di 0.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Livello di creatività non valido.

Inserisci un numero tra 0 e 2.
"
LLM_CONTENT_INVALID_TOP_P="
Livello di focus non valido.

Inserisci un numero tra 0 e 1.
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

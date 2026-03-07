#!/usr/bin/env bash
LLM_TITLE_SETUP="Instal·lació d'Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Heu seleccionat la funció LLM per a ovos-persona.

Això permet que OVOS utilitzi un assistent d'IA quan les habilitats normals no tenen una bona resposta.

Se us demanarà:
  - URL de l'API: on OVOS envia les peticions d'IA
  - Clau API: la vostra clau privada d'accés a aquest servei
  - Model: quin model d'IA cal utilitzar
  - Estil de l'assistent: com ha de sonar l'assistent
  - Longitud de la resposta: quant espai té el model per respondre
  - Creativitat: valors baixos són més segurs, valors alts més imaginatius
  - Enfocament: valors baixos mantenen les respostes més ajustades i previsibles

Les opcions avançades ja inclouen valors segurs per defecte.
"
LLM_TITLE_EXISTING="Instal·lació d'Open Voice OS - Configuració LLM existent"
LLM_CONTENT_EXISTING="
S'ha detectat una configuració de persona LLM existent.

URL de l'API: __URL__
Model: __MODEL__

Voleu mantenir la configuració existent?
"
LLM_TITLE_URL="Instal·lació d'Open Voice OS - URL de l'API LLM"
LLM_CONTENT_URL="
Introduïu la URL d'API compatible amb OpenAI que utilitza el vostre proveïdor.

Exemple: https://llama.smartgic.io/v1

Consell: molts servidors compatibles necessiten la part /v1.
"
LLM_TITLE_KEY="Instal·lació d'Open Voice OS - Clau API LLM"
LLM_CONTENT_KEY="
Introduïu la clau API del vostre proveïdor d'IA.

Aquesta clau es manté privada i no es mostra al resum de l'instal·lador.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Deixeu-ho en blanc per mantenir la clau existent.
"
LLM_TITLE_MODEL="Instal·lació d'Open Voice OS - Model LLM"
LLM_CONTENT_MODEL="
Introduïu el nom del model que OVOS ha d'utilitzar per a les converses.

Exemples: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Instal·lació d'Open Voice OS - Estil de l'assistent LLM"
LLM_CONTENT_PERSONA="
Descriviu com ha de parlar i comportar-se l'assistent.

El valor predeterminat està ajustat per a respostes curtes i adequades per a veu.
Exemple: Respon en català planer per a un assistent de veu. Sense emojis. Respostes breus.
"
LLM_TITLE_MAX_TOKENS="Instal·lació d'Open Voice OS - Longitud de la resposta LLM"
LLM_CONTENT_MAX_TOKENS="
Trieu quant espai té el model per a cada resposta.

Valors més alts permeten respostes més completes però poden ser més lentes.
Valors més baixos fan respostes més curtes i ràpides.

Recomanat per a ús amb veu: 300
"
LLM_TITLE_TEMPERATURE="Instal·lació d'Open Voice OS - Creativitat LLM"
LLM_CONTENT_TEMPERATURE="
Trieu com de creatives han de ser les respostes.

Els valors baixos són més tranquils i previsibles.
Els valors alts són més juganers i variats.

Recomanat per a ús amb veu: 0.2
"
LLM_TITLE_TOP_P="Instal·lació d'Open Voice OS - Enfocament LLM"
LLM_CONTENT_TOP_P="
Trieu com de fortament el model s'ha de mantenir en les paraules més probables.

Els valors baixos fan les respostes més enfocades i constants.
Els valors alts permeten més varietat.

Recomanat per a ús amb veu: 0.1
"
LLM_TITLE_INVALID="Instal·lació d'Open Voice OS - Configuració LLM no vàlida"
LLM_CONTENT_MISSING_INFO="
Falta informació LLM requerida.

Proporcioneu URL de l'API, clau API, model, estil de l'assistent i valors d'ajust.
"
LLM_CONTENT_INVALID_URL="
URL no vàlida.

Proporcioneu una URL d'API compatible amb OpenAI vàlida.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Longitud de resposta no vàlida.

Introduïu un nombre enter superior a 0.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Nivell de creativitat no vàlid.

Introduïu un nombre entre 0 i 2.
"
LLM_CONTENT_INVALID_TOP_P="
Nivell d'enfocament no vàlid.

Introduïu un nombre entre 0 i 1.
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

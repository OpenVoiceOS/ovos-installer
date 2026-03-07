#!/usr/bin/env bash
LLM_TITLE_SETUP="Open Voice OS instalazioa - LLM"
LLM_CONTENT_HAVE_DETAILS="
ovos-persona-rako LLM funtzioa hautatu duzu.

Honek OVOSi IA laguntzaile bat erabiltzea ahalbidetzen dio, trebetasun arruntek erantzun onik ez dutenean.

Honako hauek eskatuko zaizkizu:
  - API URLa: OVOSek IA eskaerak nora bidaltzen dituen
  - API gakoa: zerbitzu horretarako zure sarbide-gako pribatua
  - Modeloa: zein IA modelo erabili behar den
  - Laguntzailearen estiloa: laguntzaileak nola hitz egin behar duen
  - Erantzunaren luzera: modeloak zenbat tarte duen erantzuteko
  - Sormena: balio baxuak seguruagoak dira, balio altuak irudimentsuagoak
  - Fokua: balio baxuek erantzunak estuago eta aurresangarriago mantentzen dituzte

Aukera aurreratuetan lehenetsitako balio seguruak daude jada.
"
LLM_TITLE_EXISTING="Open Voice OS instalazioa - Dagoen LLM konfigurazioa"
LLM_CONTENT_EXISTING="
Lehendik dagoen LLM pertsona konfigurazioa aurkitu da.

API URLa: __URL__
Modeloa: __MODEL__

Lehendik dagoen konfigurazioa mantendu nahi duzu?
"
LLM_TITLE_URL="Open Voice OS instalazioa - LLM API URLa"
LLM_CONTENT_URL="
Sartu zure hornitzaileak erabiltzen duen OpenAI bateragarria den API URLa.

Adibidea: https://llama.smartgic.io/v1

Aholkua: zerbitzari bateragarri askok /v1 zatia behar dute.
"
LLM_TITLE_KEY="Open Voice OS instalazioa - LLM API gakoa"
LLM_CONTENT_KEY="
Sartu zure IA hornitzailearen API gakoa.

Pribatua izango da eta ez da instalatzailearen laburpenean erakutsiko.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Utzi hutsik lehendik duzun gakoa mantentzeko.
"
LLM_TITLE_MODEL="Open Voice OS instalazioa - LLM modeloa"
LLM_CONTENT_MODEL="
Sartu OVOSek elkarrizketetarako erabili behar duen modeloaren izena.

Adibideak: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Open Voice OS instalazioa - LLM laguntzailearen estiloa"
LLM_CONTENT_PERSONA="
Azaldu laguntzaileak nola hitz egin eta jokatu behar duen.

Lehenetsia ahots bidezko erantzun laburretarako egokituta dago.
Adibidea: Erantzun euskara arruntean ahots laguntzaile baterako. Emojirik ez. Erantzun laburrak.
"
LLM_TITLE_MAX_TOKENS="Open Voice OS instalazioa - LLM erantzunaren luzera"
LLM_CONTENT_MAX_TOKENS="
Aukeratu modeloak erantzun bakoitzerako zenbat tarte duen.

Balio altuek erantzun osoagoak ahalbidetzen dituzte, baina motelagoak izan daitezke.
Balio baxuek erantzun laburragoak eta azkarragoak ematen dituzte.

Ahots erabilerarako gomendatua: 300
"
LLM_TITLE_TEMPERATURE="Open Voice OS instalazioa - LLM sormena"
LLM_CONTENT_TEMPERATURE="
Aukeratu erantzunak zenbateraino izan behar diren sortzaileak.

Balio baxuak lasaiagoak eta aurresangarriagoak dira.
Balio altuak jostariagoak eta askotarikoagoak dira.

Ahots erabilerarako gomendatua: 0.2
"
LLM_TITLE_TOP_P="Open Voice OS instalazioa - LLM fokua"
LLM_CONTENT_TOP_P="
Aukeratu modeloak hitz probableenetan zenbateraino mantendu behar duen.

Balio baxuek erantzunak fokuratuagoak eta koherenteagoak egiten dituzte.
Balio altuek barietate handiagoa uzten dute.

Ahots erabilerarako gomendatua: 0.1
"
LLM_TITLE_INVALID="Open Voice OS instalazioa - LLM konfigurazio baliogabea"
LLM_CONTENT_MISSING_INFO="
Beharrezko LLM informazio batzuk falta dira.

Eman API URLa, API gakoa, modeloa, laguntzailearen estiloa eta doikuntza-balioak.
"
LLM_CONTENT_INVALID_URL="
URL baliogabea.

Eman OpenAI bateragarria den API URL baliodun bat.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Erantzunaren luzera baliogabea.

Sartu 0 baino handiagoa den zenbaki oso bat.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Sormen maila baliogabea.

Sartu 0 eta 2 arteko zenbaki bat.
"
LLM_CONTENT_INVALID_TOP_P="
Foku maila baliogabea.

Sartu 0 eta 1 arteko zenbaki bat.
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

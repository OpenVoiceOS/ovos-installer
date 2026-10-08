#!/usr/bin/env bash
CONTENT="
Open Voice OS zamienia mowę na tekst (rozpoznawanie) i czyta odpowiedzi na głos (synteza).

  - local: ten komputer z serwerami publicznymi w rezerwie. Pobiera modele mowy (od setek megabajtów do kilku gigabajtów). Jeśli lokalne rozpoznawanie zawiedzie lub nie zwróci tekstu, nagranie jest wysyłane do serwerów publicznych. Jeśli nie da się skonfigurować lokalnego rozpoznawania lub syntezy, ta część używa serwerów publicznych; instalator o tym informuje.
  - public: serwery społeczności przetwarzają Twoje nagrania i odpowiedzi głosowe przez internet. Te zapasowe serwery prowadzone przez wolontariuszy nie są usługą produkcyjną: mogą zwolnić lub przestać działać w każdej chwili.

Wybierz, gdzie ma być przetwarzana mowa:
"
TITLE="Instalacja Open Voice OS - Mowa"
LOCAL_DESCRIPTION="Ten komputer z serwerami publicznymi w rezerwie"
PUBLIC_DESCRIPTION="Serwery publiczne (wiem, że mogą przestać działać)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

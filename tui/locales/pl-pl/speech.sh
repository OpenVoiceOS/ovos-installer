#!/usr/bin/env bash
CONTENT="
Open Voice OS zamienia to, co mówisz, na tekst (rozpoznawanie mowy) i czyta swoje odpowiedzi na głos (synteza mowy). Ten komputer jest na tyle wydajny, żeby robić jedno i drugie samodzielnie.

- local: wszystko działa na tym komputerze. Twój głos zostaje tutaj i nic nie zależy od internetu ani od obciążenia serwerów. Instalator pobiera modele mowy dla Twojego języka, od kilkuset megabajtów do kilku gigabajtów, a rozpoznawanie obciąża procesor, gdy mówisz.
- public: pracę wykonują publiczne serwery Open Voice OS. Nic nie trzeba pobierać, ale każde żądanie wędruje przez internet do serwerów współdzielonych przez całą społeczność, co dodaje opóźnienie sieciowe i spowalnia działanie, gdy korzysta z nich wiele osób naraz. Twoje nagrania i odpowiedzi są przetwarzane na tych serwerach.

Jeśli lokalne rozpoznawanie zawiedzie lub nic nie usłyszy, to nagranie zostanie wysłane do serwerów publicznych.

Wybierz, gdzie ma być przetwarzana mowa:
"
TITLE="Instalacja Open Voice OS - Mowa"
LOCAL_DESCRIPTION="Przetwarzaj mowę na tym komputerze"
PUBLIC_DESCRIPTION="Używaj publicznych serwerów Open Voice OS"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

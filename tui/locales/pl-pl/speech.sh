#!/usr/bin/env bash
CONTENT="
Open Voice OS zamienia to, co mówisz, na tekst (rozpoznawanie mowy) i czyta swoje odpowiedzi na głos (synteza mowy). Ten komputer jest na tyle wydajny, żeby robić jedno i drugie samodzielnie.

- local: wszystko działa na tym komputerze. Twój głos zostaje tutaj i nic nie zależy od internetu ani od obciążenia serwerów. Instalator pobiera modele mowy dla Twojego języka, od kilkuset megabajtów do kilku gigabajtów, a rozpoznawanie obciąża procesor, gdy mówisz.
- public: pracę wykonują serwery społeczności. Działają w dobrej wierze, jako zapas i przykład samodzielnie hostowanego przetwarzania mowy, a nie jako usługa produkcyjna: odpowiedzi zwalniają, gdy korzysta z nich wiele osób naraz, a serwery w każdej chwili mogą przestać działać. Nic nie trzeba pobierać, ale Twoje nagrania i odpowiedzi trafiają przez internet na te serwery i tam są przetwarzane.

Jeśli lokalne rozpoznawanie zawiedzie lub nic nie usłyszy, to nagranie zostanie wysłane do serwerów publicznych.

Wybierz, gdzie ma być przetwarzana mowa:
"
TITLE="Instalacja Open Voice OS - Mowa"
LOCAL_DESCRIPTION="Przetwarzaj mowę na tym komputerze"
PUBLIC_DESCRIPTION="Serwery publiczne (wiem, że mogą przestać działać)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

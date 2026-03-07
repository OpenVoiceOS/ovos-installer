#!/usr/bin/env bash
LLM_TITLE_SETUP="Instalacja Open Voice OS - LLM"
LLM_CONTENT_HAVE_DETAILS="
Wybrano funkcję LLM dla ovos-persona.

Dzięki temu OVOS może używać asystenta AI, gdy zwykłe umiejętności nie mają dobrej odpowiedzi.

Zostaniesz poproszony o:
  - URL API: dokąd OVOS wysyła żądania AI
  - Klucz API: Twój prywatny klucz dostępu do tej usługi
  - Model: którego modelu AI użyć
  - Styl asystenta: jak asystent ma brzmieć
  - Długość odpowiedzi: ile miejsca model ma na odpowiedź
  - Kreatywność: niższe wartości są bezpieczniejsze, wyższe bardziej pomysłowe
  - Skupienie: niższe wartości dają ciaśniejsze i bardziej przewidywalne odpowiedzi

Dla opcji zaawansowanych bezpieczne wartości domyślne są już wpisane.
"
LLM_TITLE_EXISTING="Instalacja Open Voice OS - Istniejące ustawienia LLM"
LLM_CONTENT_EXISTING="
Wykryto istniejącą konfigurację persony LLM.

URL API: __URL__
Model: __MODEL__

Czy chcesz zachować istniejącą konfigurację?
"
LLM_TITLE_URL="Instalacja Open Voice OS - URL API LLM"
LLM_CONTENT_URL="
Wprowadź adres URL API kompatybilny z OpenAI używany przez Twojego dostawcę.

Przykład: https://llama.smartgic.io/v1

Wskazówka: wiele kompatybilnych serwerów wymaga części /v1.
"
LLM_TITLE_KEY="Instalacja Open Voice OS - Klucz API LLM"
LLM_CONTENT_KEY="
Wprowadź klucz API swojego dostawcy AI.

Pozostaje on prywatny i nie jest pokazywany w podsumowaniu instalatora.
"
LLM_CONTENT_KEY_KEEP_EXISTING="
Pozostaw puste, aby zachować istniejący klucz.
"
LLM_TITLE_MODEL="Instalacja Open Voice OS - Model LLM"
LLM_CONTENT_MODEL="
Wprowadź nazwę modelu, którego OVOS ma używać do rozmów.

Przykłady: gpt-4o-mini, llama3.1:8b, qwen3-nothink:latest
"
LLM_TITLE_PERSONA="Instalacja Open Voice OS - Styl asystenta LLM"
LLM_DEFAULT_PERSONA="Odpowiadaj w języku użytkownika prostym, naturalnym stylem mówionym dla asystenta głosowego. Bez emoji. Bez markdownu. Bez wypunktowań. Bez wtrąceń w nawiasach. Odpowiedzi mają być zwięzłe, zwykle jedno albo dwa krótkie zdania. Zacznij od razu od odpowiedzi i zadbaj, by brzmiała naturalnie po przeczytaniu na głos."
LLM_CONTENT_PERSONA="
Opisz, jak asystent ma mówić i się zachowywać.

Domyślna wartość jest ustawiona pod krótkie odpowiedzi odpowiednie do głosu.
Przykład: Odpowiadaj prostą polszczyzną dla asystenta głosowego. Bez emoji. Krótkie odpowiedzi.
"
LLM_TITLE_MAX_TOKENS="Instalacja Open Voice OS - Długość odpowiedzi LLM"
LLM_CONTENT_MAX_TOKENS="
Wybierz, ile miejsca model ma na każdą odpowiedź.

Wyższe wartości pozwalają na pełniejsze odpowiedzi, ale mogą być wolniejsze.
Niższe wartości dają odpowiedzi krótsze i szybsze.

Zalecane do użycia głosowego: 300
"
LLM_TITLE_TEMPERATURE="Instalacja Open Voice OS - Kreatywność LLM"
LLM_CONTENT_TEMPERATURE="
Wybierz, jak kreatywne mają być odpowiedzi.

Niższe wartości są spokojniejsze i bardziej przewidywalne.
Wyższe wartości są bardziej różnorodne i swobodne.

Zalecane do użycia głosowego: 0.2
"
LLM_TITLE_TOP_P="Instalacja Open Voice OS - Skupienie LLM"
LLM_CONTENT_TOP_P="
Wybierz, jak mocno model ma trzymać się najbardziej prawdopodobnych słów.

Niższe wartości dają odpowiedzi bardziej spójne i skupione.
Wyższe wartości pozwalają na większą różnorodność.

Zalecane do użycia głosowego: 0.1
"
LLM_TITLE_INVALID="Instalacja Open Voice OS - Nieprawidłowa konfiguracja LLM"
LLM_CONTENT_MISSING_INFO="
Brakuje wymaganych informacji LLM.

Podaj URL API, klucz API, model, styl asystenta i wartości strojenia.
"
LLM_CONTENT_INVALID_URL="
Nieprawidłowy URL.

Podaj prawidłowy URL API kompatybilny z OpenAI.
"
LLM_CONTENT_INVALID_MAX_TOKENS="
Nieprawidłowa długość odpowiedzi.

Wprowadź liczbę całkowitą większą od 0.
"
LLM_CONTENT_INVALID_TEMPERATURE="
Nieprawidłowy poziom kreatywności.

Wprowadź liczbę od 0 do 2.
"
LLM_CONTENT_INVALID_TOP_P="
Nieprawidłowy poziom skupienia.

Wprowadź liczbę od 0 do 1.
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

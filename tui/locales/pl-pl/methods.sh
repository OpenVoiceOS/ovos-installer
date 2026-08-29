#!/usr/bin/env bash
CONTENT="
Aby zainstalować Open Voice OS, masz dwie podstawowe metody:

- Silnik kontenerów, taki jak Docker
- Konfiguracja w wirtualnym środowisku Python

Kontenery zapewniają izolację i łatwe wdrażanie, podczas gdy wirtualne środowisko Python oferuje większą elastyczność i kontrolę nad instalacją.

Jeśli wybierzesz metodę kontenerów, Docker zostanie zainstalowany automatycznie, jeśli nie jest obecny w systemie.

Wybierz metodę instalacji:
"
LOCKED_CONTENT="
Wykryto istniejącą instalację Open Voice OS, dlatego dostępna jest tylko metoda, której już używa:

    - Wykryta metoda: $INSTANCE_TYPE

Aby zainstalować inną metodą, najpierw odinstaluj istniejącą instancję, a następnie ponownie uruchom instalator.

Potwierdź metodę instalacji:
"
TITLE="Instalacja Open Voice OS - Metody"

export CONTENT LOCKED_CONTENT TITLE

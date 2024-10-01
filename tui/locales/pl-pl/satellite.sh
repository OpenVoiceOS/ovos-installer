#!/bin/env bash

# Global message
content="Łącząc się z odbiornikiem HiveMind, satelity HiveMind uzyskują dostęp do sieci współdzielonej wiedzy i możliwości, co umożliwia korzystanie ze zintegrowanego i wydajnego asystenta głosowego oraz automatyzacji."

# Host
CONTENT_HOST="
$content

Proszę wprowadzić adres hosta nasłuchującego HiveMind (adres DNS lub IP):
"

# Port
CONTENT_PORT="
$content

Proszę wprowadzić port nasłuchu HiveMind:
"

# Key
CONTENT_KEY="
$content

Proszę wprowadzić klucz nasłuchu HiveMind związany z satelitą:
"

# Password
CONTENT_PASSWORD="
$content

Proszę wprowadzić hasło nasłuchujące HiveMind powiązane z satelitą:
"

TITLE_HOST="Instalacja Open Voice OS - Satellite 1/4"
TITLE_PORT="Instalacja Open Voice OS - Satellite 2/4"
TITLE_KEY="Instalacja Open Voice OS - Satellite 3/4"
TITLE_PASSWORD="Instalacja Open Voice OS - Satellite 4/4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

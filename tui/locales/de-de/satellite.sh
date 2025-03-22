#!/bin/env bash

# Global message
content="Durch die Verbindung mit dem HiveMind-Listener erhalten die HiveMind-Satelliten Zugang zu einem zentralen lokalen Dienst, der eine einheitliche und effiziente Sprachassistenz und Automatisierung ermöglicht."

# Host
CONTENT_HOST="
$content

Gib den HiveMind listener host ein(DNS oder IP Addrese):
"

# Port
CONTENT_PORT="
$content

Gib den HiveMind listener Port ein:
"

# Key
CONTENT_KEY="
$content

Gib den HiveMind listener Zugangsschlüssel des Satelliten ein:
"

# Password
CONTENT_PASSWORD="
$content

Gib das HiveMind listener Passwort des Satelliten ein:
"

TITLE_HOST="Open Voice OS Installation - Satellit 1 von 4"
TITLE_PORT="Open Voice OS Installation - Satellit 2 von 4"
TITLE_KEY="Open Voice OS Installation - Satellit 3 von 4"
TITLE_PASSWORD="Open Voice OS Installation - Satellit 4 von 4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

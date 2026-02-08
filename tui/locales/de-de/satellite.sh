#!/usr/bin/env bash
# Global message
content="Durch die Verbindung mit dem HiveMind-Listener erhalten die HiveMind-Satelliten Zugang zu einem zentralen lokalen Dienst, der eine einheitliche und effiziente Sprachassistenz und Automatisierung ermöglicht."

# Host
CONTENT_HOST="
$content

Geben Sie  den DNS oder die IP Adresse des HiveMind Servers ein :
"

# Port
CONTENT_PORT="
$content

Geben Sie die Portnummer des HiveMind Servers ein:
"

# Key
CONTENT_KEY="
$content

Geben Sie den  Zugangsschlüssel des Satelliten für den HiveMind Server ein:
"

# Password
CONTENT_PASSWORD="
$content

Geben Sie das Passwort des Satelliten für den HiveMind Server  ein:
"

TITLE_HOST="Open Voice OS Installation - Satellit 1 von 4"
TITLE_PORT="Open Voice OS Installation - Satellit 2 von 4"
TITLE_KEY="Open Voice OS Installation - Satellit 3 von 4"
TITLE_PASSWORD="Open Voice OS Installation - Satellit 4 von 4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

#!/bin/env bash

# Global message
content="Ved at oprette forbindelse til HiveMind-lytteren får HiveMind-satellitter adgang til et netværk af delt viden og muligheder, hvilket letter en samlet og effektiv stemmeassistent og automatiseringsoplevelse."

# Host
CONTENT_HOST="
$content

Indtast venligst HiveMind-lytterværten (DNS- eller IP-adresse):
"

# Port
CONTENT_PORT="
$content

Indtast venligst HiveMind-lytterporten:
"

# Key
CONTENT_KEY="
$content

Indtast venligst HiveMind-lytternøglen relateret til satellitten:
"

# Password
CONTENT_PASSWORD="
$content

Indtast venligst HiveMind-lytteradgangskoden relateret til satellitten:
"

TITLE_HOST="Open Voice OS Installation - Satellit 1/4"
TITLE_PORT="Open Voice OS Installation - Satellite 2/4"
TITLE_KEY="Open Voice OS Installation - Satellite 3/4"
TITLE_PASSWORD="Open Voice OS Installation - Satellite 4/4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

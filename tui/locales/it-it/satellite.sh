#!/bin/env bash

# Global message
content="Collegandosi all'HiveMind Listener, i satelliti HiveMind accedono a una rete di conoscenze e competenze condivise che consente un'assistenza linguistica e un'automazione unificate ed efficienti."

# Host
CONTENT_HOST="
$content

Inserire l'host dell'ascoltatore HiveMind (DNS o indirizzo IP):
"

# Port
CONTENT_PORT="
$content

Inserire la porta dell'ascoltatore HiveMind:
"

# Key
CONTENT_KEY="
$content

Immettere la chiave di ascolto HiveMind del satellite:
"

# Password
CONTENT_PASSWORD="
$content

Inserire la password dell'ascoltatore HiveMind del satellite:
"

TITLE_HOST="Open Voice OS Installation - Satellite 1/4"
TITLE_PORT="Open Voice OS Installation - Satellite 2/4"
TITLE_KEY="Open Voice OS Installation - Satellite 3/4"
TITLE_PASSWORD="Open Voice OS Installation - Satellite 4/4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

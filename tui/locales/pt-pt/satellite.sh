#!/bin/env bash

# Global message
content="Ao ligarem-se ao HiveMind Listener, os satélites HiveMind ganham acesso a uma rede de conhecimentos e competências partilhados que permite uma assistência e automatização linguística unificada e eficiente."

# Host
CONTENT_HOST="
$content

Introduza o anfitrião do ouvinte do HiveMind (endereço DNS ou IP):
"

# Port
CONTENT_PORT="
$content

Introduza a porta do ouvinte do HiveMind:
"

# Key
CONTENT_KEY="
$content

Introduza a chave de escuta HiveMind do satélite:
"

# Password
CONTENT_PASSWORD="
$content

Introduza a palavra-passe do ouvinte HiveMind do satélite:
"

TITLE_HOST="Open Voice OS Installation - Satélite 1/4"
TITLE_PORT="Open Voice OS Installation - Satélite 2/4"
TITLE_KEY="Open Voice OS Installation - Satélite 3/4"
TITLE_PASSWORD="Open Voice OS Installation - Satélite 4/4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

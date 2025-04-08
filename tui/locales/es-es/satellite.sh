#!/bin/env bash

# Global message
content="Al conectarse al HiveMind Listener, los satélites HiveMind acceden a una red de conocimientos y competencias compartidos que permite una asistencia lingüística y una automatización unificadas y eficaces."

# Host
CONTENT_HOST="
$content

Introduce el host de escucha HiveMind (DNS o dirección IP):
"

# Port
CONTENT_PORT="
$content

Introduce el puerto de escucha HiveMind:
"

# Key
CONTENT_KEY="
$content

Introduce la clave de escucha HiveMind del satélite:
"

# Password
CONTENT_PASSWORD="
$content

Introduce la contraseña de escucha HiveMind del satélite:
"

TITLE_HOST="Open Voice OS Installation - Satélite 1/4"
TITLE_PORT="Open Voice OS Installation - Satélite 2/4"
TITLE_KEY="Open Voice OS Installation - Satélite 3/4"
TITLE_PASSWORD="Open Voice OS Installation - Satélite 4/4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

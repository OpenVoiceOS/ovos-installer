#!/bin/env bash

# Global message
content="En connectar-se a l'oient HiveMind, els satèl·lits HiveMind tenen accés a una xarxa de coneixements i capacitats compartides, facilitant una experiència d'automatització i assistent de veu unificada i eficient."

# Host
CONTENT_HOST="
$content

Introduïu l'amfitrió de l'escolta HiveMind (DNS o adreça IP):
"

# Port
CONTENT_PORT="
$content

Introduïu el port d'escolta de HiveMind:
"

# Key
CONTENT_KEY="
$content

Introduïu la clau d'escolta HiveMind relacionada amb el satèl·lit:
"

# Password
CONTENT_PASSWORD="
$content

Introduïu la contrasenya de l'escolta de HiveMind relacionada amb el satèl·lit:
"

TITLE_HOST="Instal·lació de l'Open VoiceOS - Satèl·lit 1/4"
TITLE_PORT="Instal·lació de l'Open VoiceOS - Satèl·lit 2/4"
TITLE_KEY="Instal·lació de l'Open VoiceOS - Satèl·lit 3/4"
TITLE_PASSWORD="Instal·lació de l'Open VoiceOS - Satellite 4/4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

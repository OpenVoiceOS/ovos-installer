#!/bin/env bash

# Global message
content="En se connectant à HiveMind Listener, les satellites HiveMind accèdent à un réseau de connaissances et de capacités partagées, facilitant ainsi une expérience d'assistance vocale unifiée et efficace."

# Host
CONTENT_HOST="
$content

Veuillez saisir l'hôte d'HiveMind Listener (DNS ou adresse IP):
"

# Port
CONTENT_PORT="
$content

Veuillez entrer le port d'écoute d'HiveMind Listener:
"

# Key
CONTENT_KEY="
$content

Veuillez saisir la clé d'HiveMind Listener liée au satellite:
"

# Password
CONTENT_PASSWORD="
$content

Veuillez saisir le mot de passe d'HiveMind Listener lié au satellite:
"

TITLE_HOST="Open Voice OS Installation - Satellite 1/4"
TITLE_PORT="Open Voice OS Installation - Satellite 2/4"
TITLE_KEY="Open Voice OS Installation - Satellite 3/4"
TITLE_PASSWORD="Open Voice OS Installation - Satellite 4/4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

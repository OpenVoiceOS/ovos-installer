#!/bin/env bash

# Global message
content="By connecting to the HiveMind listener, HiveMind satellites gain access to a network of shared knowledge and capabilities, facilitating a unified and efficient voice assistant and automation experience."

# Host
CONTENT_HOST="
$content

Please enter the HiveMind listener host (DNS or IP address):
"

# Port
CONTENT_PORT="
$content

Please enter the HiveMind listener port:
"

# Key
CONTENT_KEY="
$content

Please enter the HiveMind listener key related to the satellite:
"

# Password
CONTENT_PASSWORD="
$content

Please enter the HiveMind listener password related to the satellite:
"

TITLE_HOST="Open Voice OS Installation - Satellite 1/4"
TITLE_PORT="Open Voice OS Installation - Satellite 2/4"
TITLE_KEY="Open Voice OS Installation - Satellite 3/4"
TITLE_PASSWORD="Open Voice OS Installation - Satellite 4/4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

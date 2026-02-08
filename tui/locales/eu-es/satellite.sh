#!/usr/bin/env bash
# Global message
content="HiveMind entzulearekin konektatuz, HiveMind sateliteek ezagutza eta gaitasun partekatuen sare batera sarbidea lortzen dute, ahots-laguntzaile eta automatizazio esperientzia bateratu eta eraginkorra erraztuz."

# Host
CONTENT_HOST="
$content

Mesedez, sartu HiveMind entzule-ostalaria (DNS edo IP helbidea):
"

# Port
CONTENT_PORT="
$content

Sartu HiveMind entzule-ataka:
"

# Key
CONTENT_KEY="
$content

Mesedez, sartu satelitearekin erlazionatutako HiveMind entzule-gakoa:
"

# Password
CONTENT_PASSWORD="
$content

Mesedez, idatzi satelitearekin erlazionatutako HiveMind entzulearen pasahitza:
"

TITLE_HOST="Ireki Voice OS instalazioa - Satelitea 1/4"
TITLE_PORT="Ireki Voice OS instalazioa - Satelite 2/4"
TITLE_KEY="Ireki Voice OS instalazioa - Satelite 3/4"
TITLE_PASSWORD="Ireki Voice OS instalazioa - Satellite 4/4"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

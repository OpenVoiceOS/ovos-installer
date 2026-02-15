#!/usr/bin/env bash

TITLE_HAVE_DETAILS="Open Voice OS Installation - Home Assistant"
CONTENT_HAVE_DETAILS="
Home Assistant integration allows OVOS to query and control entities via the Home Assistant REST API.

To enable it now, you will need:
  - Your Home Assistant URL (example: http://homeassistant.local:8123)
  - A Home Assistant Long-Lived Access Token

How to create a Long-Lived Access Token in Home Assistant:
  1) Open your Home Assistant web UI
  2) Click your user/profile (your name) in the sidebar
  3) Go to Security
  4) Under Long-Lived Access Tokens, click Create Token
  5) Copy the token and paste it here

Do you have these details now?
"

TITLE_URL="Open Voice OS Installation - Home Assistant URL"
CONTENT_URL="
Please enter your Home Assistant URL.

If you omit the port, 8123 will be used.
Example: http://homeassistant.local:8123
"

TITLE_TOKEN="Open Voice OS Installation - Home Assistant Token"
CONTENT_TOKEN="
Please paste a Home Assistant Long-Lived Access Token.

Create one in Home Assistant:
  Profile (your name) -> Security -> Long-Lived Access Tokens -> Create Token
"

TITLE_INVALID="Open Voice OS Installation - Home Assistant"
CONTENT_INVALID_URL="
Invalid URL.

The Home Assistant URL must start with http:// or https://
Example: http://homeassistant.local:8123
"

CONTENT_INVALID_PORT="
Invalid URL.

If you specify a port, it must be numeric.
Example: http://homeassistant.local:8123
"

CONTENT_MISSING_INFO="
Missing information.

Please provide the required value to enable Home Assistant integration.
"

export \
  TITLE_HAVE_DETAILS CONTENT_HAVE_DETAILS \
  TITLE_URL CONTENT_URL \
  TITLE_TOKEN CONTENT_TOKEN \
  TITLE_INVALID CONTENT_INVALID_URL \
  CONTENT_INVALID_PORT \
  CONTENT_MISSING_INFO

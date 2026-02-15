#!/usr/bin/env bash

TITLE_HAVE_DETAILS="Open Voice OS Installation - Home Assistant"
CONTENT_HAVE_DETAILS="
Home Assistant integration allows OVOS to query and control entities via the Home Assistant REST API.

To enable it now, you will need:
  - Your Home Assistant URL (example: http://homeassistant.local:8123)
  - A Home Assistant Long-Lived Access Token

Do you have these details now?
"

TITLE_URL="Open Voice OS Installation - Home Assistant URL"
CONTENT_URL="
Please enter your Home Assistant URL (example: http://homeassistant.local:8123):
"

TITLE_TOKEN="Open Voice OS Installation - Home Assistant Token"
CONTENT_TOKEN="
Please paste a Home Assistant Long-Lived Access Token:
"

TITLE_INVALID="Open Voice OS Installation - Home Assistant"
CONTENT_INVALID_URL="
Invalid URL.

The Home Assistant URL must start with http:// or https://
Example: http://homeassistant.local:8123
"

CONTENT_MISSING_INFO="
Missing information.

Home Assistant integration will be skipped.
"

export \
  TITLE_HAVE_DETAILS CONTENT_HAVE_DETAILS \
  TITLE_URL CONTENT_URL \
  TITLE_TOKEN CONTENT_TOKEN \
  TITLE_INVALID CONTENT_INVALID_URL \
  CONTENT_MISSING_INFO


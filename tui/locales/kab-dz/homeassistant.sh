#!/usr/bin/env bash

TITLE_HAVE_DETAILS="Asbeddi n Open Voice OS - Home Assistant"
CONTENT_HAVE_DETAILS="
Tuqqna ɣer Home Assistant tettak afus i OVOS akken ad yesteqsi yerna ad yesseḥbibir ɣef tɣawsiwin s useqdec n Home Assistant REST API.

Akken ad tt-rmedeḍ tura, ad teḥwaǧeḍ:
- URL n Home Assistant-ik (amedya: http://homeassistant.local:8123)
- Token n unekcum n Home Assistant (Long-Lived Access Token)

Amek ara tesnulfuḍ Token n unekcum deg Home Assistant:
1) Ldi asebter-ik n Home Assistant
2) Sit ɣef umiḍan-ik (isem-ik) deg ugalis adisan
3) Ddu ɣer Tɣellist (Security)
4) Seddaw Long-Lived Access Tokens, sit ɣef Create Token
5) Nɣel token-nni yerna sekcem-it dagi

Ɣur-k iferdisen-agi tura?
"

TITLE_EXISTING="Asbeddi n Open Voice OS - Home Assistant"
CONTENT_EXISTING="
Tuqqna ɣer Home Assistant tettwaswel yakan.

URL: __URL__
Token: (yeffer)

Tebɣiḍ ad teṭṭfeḍ tawila-nni yellan?
"

TITLE_URL="Asbeddi n Open Voice OS - URL n Home Assistant"
CONTENT_URL="
Ttxil-k sekcem URL n Home Assistant-ik.

Ma tesseqdaceḍ http:// yerna ur d-tenniḍ ara tabburt (port), 8123 ara yettwaseqdec.
Ma tesseqdaceḍ https:// yerna ur d-tenniḍ ara tabburt, ulac tabburt ara yettwarnun.
Amedya: http://homeassistant.local:8123
"

TITLE_TOKEN="Asbeddi n Open Voice OS - Token n Home Assistant"
CONTENT_TOKEN="
Ttxil-k senṭeḍ Token n unekcum n Home Assistant (Long-Lived Access Token).

Snulfu-d yiwen deg Home Assistant:
Amiḍan (isem-ik) -> Tɣellist -> Long-Lived Access Tokens -> Create Token
"

CONTENT_TOKEN_KEEP_EXISTING="
Eǧǧ-it d ilem akken ad teṭṭfeḍ token-ik yellan.
"

TITLE_INVALID="Asbeddi n Open Voice OS - Home Assistant"
CONTENT_INVALID_URL="
URL d arameɣtu.

URL n Home Assistant ilaq ad yebdu s http:// neɣ https://
Amedya: http://homeassistant.local:8123
"

CONTENT_INVALID_PORT="
URL d arameɣtu.

Ma tenniḍ-d tabburt (port), ilaq ad tili d uṭṭun.
Amedya: http://homeassistant.local:8123
"

CONTENT_MISSING_INFO="
Talɣut ur tecfi ara.

Ttxil-k efk azal ilaqen akken ad tremdeḍ tuqqna ɣer Home Assistant.
"

export \
TITLE_HAVE_DETAILS CONTENT_HAVE_DETAILS \
TITLE_EXISTING CONTENT_EXISTING \
TITLE_URL CONTENT_URL \
TITLE_TOKEN CONTENT_TOKEN \
TITLE_INVALID CONTENT_INVALID_URL \
CONTENT_INVALID_PORT \
CONTENT_TOKEN_KEEP_EXISTING \
CONTENT_MISSING_INFO

#!/usr/bin/env bash
CONTENT="
Open Voice OS turns speech into text (recognition) and reads replies aloud (synthesis).

  - local: use this machine with public fallback. Downloads speech models (hundreds of megabytes to a few gigabytes). If local recognition fails or returns no text, that recording is sent to public servers. If local recognition or synthesis cannot be set up, that part uses public servers; the installer reports it.
  - public: community servers process your recordings and spoken replies over the internet. These volunteer-run backup servers are not a production service: they can slow down or go offline at any time.

Please select where speech is processed:
"
TITLE="Open Voice OS Installation - Speech"
LOCAL_DESCRIPTION="This machine with public fallback"
PUBLIC_DESCRIPTION="Public servers (I accept they can go offline)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

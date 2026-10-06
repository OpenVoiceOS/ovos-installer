#!/usr/bin/env bash
CONTENT="
Open Voice OS turns what you say into text (speech recognition) and reads its answers out loud (speech synthesis). This machine is powerful enough to do both itself.

  - local: everything runs on this machine. Your voice stays here, and nothing depends on the internet or on how busy the servers are. The installer downloads the speech models for your language, from a few hundred megabytes to a few gigabytes, and recognition keeps the processor busy while you talk.
  - public: community servers do the work. They run on goodwill, as a backup and as an example of self-hosted speech, not as a production service: answers take longer when many people use them, and the servers can go offline at any time. Nothing to download, but your recordings and the answers travel over the internet and are processed on those servers.

When local recognition fails or hears nothing, that one recording is sent to the public servers instead.

Please select where speech is processed:
"
TITLE="Open Voice OS Installation - Speech"
LOCAL_DESCRIPTION="Run speech on this machine"
PUBLIC_DESCRIPTION="Public servers (I accept they can go offline)"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

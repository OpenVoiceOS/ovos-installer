#!/usr/bin/env bash
CONTENT="
Open Voice OS turns what you say into text (speech recognition) and reads its answers out loud (speech synthesis). This machine is powerful enough to do both itself.

  - local: everything runs on this machine. Your voice stays here, and nothing depends on the internet or on how busy the servers are. The installer downloads the speech models for your language, from a few hundred megabytes to a few gigabytes, and recognition keeps the processor busy while you talk.
  - public: the Open Voice OS public servers do the work. Nothing to download, but every request travels over the internet to servers the whole community shares, which adds network delay and slows down when many people use them at once. Your recordings and the answers are processed on those servers.

When local recognition fails or hears nothing, that one recording is sent to the public servers instead.

Please select where speech is processed:
"
TITLE="Open Voice OS Installation - Speech"
LOCAL_DESCRIPTION="Run speech on this machine"
PUBLIC_DESCRIPTION="Use the Open Voice OS public servers"

export CONTENT TITLE LOCAL_DESCRIPTION PUBLIC_DESCRIPTION

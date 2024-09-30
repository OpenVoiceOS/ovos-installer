#!/bin/env bash

CONTENT="
एक मौजूदा स्थापना Open Voice OS का पता चला है।

क्योंकि Docker और PipeWire सिस्टम द्वारा या मैन्युअल रूप से स्थापित किए जा सकते हैं, इंस्टॉलर निम्नलिखित पैकेजों को हटाने का प्रयास नहीं करेगा:

    - docker-ce
    - docker-compose-plugin
    - docker-ce-rootless-extras
    - docker-buildx-plugin
    - pipewire
    - pipewire-alsa

क्या आप Open Voice OS को अनइंस्टॉल करना चाहते हैं?
"
TITLE="Open Voice OS Installation - Uninstall"

export CONTENT TITLE
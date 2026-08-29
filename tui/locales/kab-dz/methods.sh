#!/usr/bin/env bash
CONTENT="
Akken ad tesbeddeḍ Open Voice OS, ɣur-k snat n tarrayin timezwura.

    - Amsedday n imagbaren am Docker
    - Naɣ asbeddi deg twennaḍt tuhlist n Python

Imagbaren ttaken-d aɛzal d usenfali afessas, ma d tawennaḍt tuhlist n Python tettak-d ugar n tiflellit d usenqed n usbeddi.

Ma tettwafren tarrayt n yimagbaren, Docker ad yettwasbedd s wudem awurman ma ulac-it deg unagraw.

Ttxil fren tarrayt n usebded:
"
LOCKED_CONTENT="
An existing installation of Open Voice OS was detected, so only the method it already uses is available:

    - Detected method: ${INSTANCE_TYPE:-}

To install with another method, uninstall the existing instance first, then run the installer again.

Please confirm the installation method:
"
TITLE="Asbeddi n Open Voice OS - Tarrayin"

export CONTENT LOCKED_CONTENT TITLE

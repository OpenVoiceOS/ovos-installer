#!/bin/env bash

installer_path="$HOME/ovos-installer"

if [[ -d "$installer_path" ]]; then
    rm -rf "$installer_path"
fi

git clone --quiet https://github.com/OpenVoiceOS/ovos-installer.git "$installer_path"
cd "$installer_path" || exit 1
bash ./setup.sh

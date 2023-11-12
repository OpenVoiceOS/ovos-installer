#!/bin/env bash

if [ -n "$SUDO_USER" ]; then
    export RUN_AS="$SUDO_USER"
    export RUN_AS_HOME="/home/$SUDO_USER"
else
    export RUN_AS=$USER
    export RUN_AS_HOME="/$SUDO_USER"
fi

if ! command -v git &> /dev/null; then
    echo "git command not found..."
    echo "Make sure to install git package before running the installer."
    exit 1
fi

installer_path="$RUN_AS_HOME/ovos-installer"

if [[ -d "$installer_path" ]]; then
    rm -rf "$installer_path"
fi

git clone --quiet https://github.com/OpenVoiceOS/ovos-installer.git "$installer_path"
cd "$installer_path" || exit 1
bash ./setup.sh

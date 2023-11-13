#!/bin/env bash

# Set global variables based on sudo usage
if [ -n "$SUDO_USER" ]; then
    export RUN_AS="$SUDO_USER"
    export RUN_AS_HOME="/home/$SUDO_USER"
else
    export RUN_AS=$USER
    export RUN_AS_HOME="/$SUDO_USER"
fi

# Check for git command to be installed
if ! command -v git &> /dev/null; then
    echo "git command not found..."
    echo "Make sure to install git package before running the installer."
    exit 1
fi

# Remove ovos-installer directory if exists
installer_path="$RUN_AS_HOME/ovos-installer"
if [[ -d "$installer_path" ]]; then
    rm -rf "$installer_path"
fi

# Clone the latest version of ovos-installer git repository
git clone --quiet https://github.com/OpenVoiceOS/ovos-installer.git "$installer_path"
cd "$installer_path" || exit 1

# Execute the installer entrypoint
bash ./setup.sh

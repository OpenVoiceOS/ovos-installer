#!/usr/bin/env sh
# Set global variables based on sudo usage
if [ -n "$SUDO_USER" ]; then
    export RUN_AS="$SUDO_USER"
else
    export RUN_AS="$USER"
fi

SYSTEM_NAME="$(uname -s 2>/dev/null || echo unknown)"

# Resolve the user's home directory without using eval (best effort).
RUN_AS_HOME=""
if command -v getent >/dev/null 2>&1; then
    RUN_AS_HOME="$(getent passwd "$RUN_AS" 2>/dev/null | awk -F: '{print $6}' | head -n 1)"
fi
if [ -z "$RUN_AS_HOME" ] && [ "$SYSTEM_NAME" = "Darwin" ] && command -v dscl >/dev/null 2>&1; then
    RUN_AS_HOME="$(dscl . -read "/Users/$RUN_AS" NFSHomeDirectory 2>/dev/null | awk '/NFSHomeDirectory:/ {print $2}' | head -n 1)"
fi
if [ -z "$RUN_AS_HOME" ]; then
    if [ "$RUN_AS" = "$USER" ] && [ -n "${HOME:-}" ]; then
        RUN_AS_HOME="$HOME"
    elif [ "$RUN_AS" = "root" ]; then
        RUN_AS_HOME="/root"
    elif [ "$SYSTEM_NAME" = "Darwin" ]; then
        RUN_AS_HOME="/Users/$RUN_AS"
    else
        RUN_AS_HOME="/home/$RUN_AS"
    fi
fi
export RUN_AS_HOME

# Check for git command to be installed
if ! command -v git >/dev/null 2>&1; then
    printf "\n\e[31m[fail]\e[0m git command not found..."
    printf "\n       Please install git package before running the installer.\n\n"
    exit 1
fi

# Remove ovos-installer directory if exists
installer_path="$RUN_AS_HOME/ovos-installer"
if [ -d "$installer_path" ]; then
    rm -rf "$installer_path"
fi

# Clone the latest version of ovos-installer git repository
sudo -u "$RUN_AS" git clone --quiet https://github.com/OpenVoiceOS/ovos-installer.git "$installer_path"
cd "$installer_path" || exit 1

# shellcheck source=utils/bash_runtime.sh
. "$installer_path/utils/bash_runtime.sh"

# Execute the installer entrypoint with a modern Bash runtime.
BASH_RUNTIME="$(resolve_bash_runtime 4 || true)"
if [ -z "$BASH_RUNTIME" ]; then
    printf "\n\e[31m[fail]\e[0m compatible bash (>=4) not found...\n"
    if [ "$SYSTEM_NAME" = "Darwin" ]; then
        printf "       Please install Bash with Homebrew first:\n"
        printf "       brew install bash\n\n"
    else
        printf "       Please install Bash 4+ before running the installer.\n\n"
    fi
    exit 5
fi
"$BASH_RUNTIME" setup.sh "$@"

# Delete ovos-installer directory once the installer is successful
exit_status="$?"
if [ "$exit_status" -eq 0 ]; then
    cd "$RUN_AS_HOME" || exit 1
    rm -rf "$installer_path"
fi

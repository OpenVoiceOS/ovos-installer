#!/bin/env bash

done_format="\e[32mdone\e[0m"

function delete_log {
    if [[ -f "$LOG_FILE" ]]; then
        rm "$LOG_FILE"
    fi
}

function detect_user {
    if [[ $EUID -ne 0 ]]; then
        echo "This script must be run as root or with sudo"
        exit 1
    fi
    if [ -n "$SUDO_USER" ]; then
        export RUN_AS="$SUDO_USER"
        export RUN_AS_UID="$SUDO_UID"
        export RUN_AS_HOME="/home/$SUDO_USER"
        export VENV_PATH="${RUN_AS_HOME}/.venvs/ovos-installer"
    else
        export RUN_AS=$USER
        export RUN_AS_UID="$EUID"
        export RUN_AS_HOME="/$SUDO_USER"
        export VENV_PATH="${RUN_AS_HOME}/.venvs/ovos-installer"
    fi
}

function is_installed {
    if ! [ -x "$(command -v "$1")" ]; then
        echo "Unable to find $1 command"s
        exit 1
    fi
}

function detect_sound {
    echo -ne "➤ Detecting sound server... "
    if pgrep -a -f -c "pulse" 1>/dev/null; then
        export PULSE_SERVER="/run/user/${RUN_AS_UID}/pulse/native"
        SOUND_SERVER="$(pactl info | awk -F":" '$1 ~ /Server Name/ { print $2}' | sed 's/^ *//')"
        export SOUND_SERVER
    elif pgrep -a -f -c "pipewire$" 1>/dev/null; then
        export SOUND_SERVER="PipeWire"
    else
        export SOUND_SERVER="N/A"
    fi
    echo -e "[$done_format]"
}

function detect_x {
    echo -ne "➤ Detecting X server... "
    export X_SERVER="N/A"
    if loginctl show-session $(loginctl | grep "$RUN_AS" | awk '{ print $1 }') -p Type | tr -s '\n' | grep -q -E "x11|wayland"; then
        sessions="$(loginctl show-session $(loginctl | grep "$RUN_AS" | awk '{ print $1 }') -p Type | tr -s '\n' | grep -E "x11|wayland")"
        if [[ "$sessions" == "Type=wayland" ]]; then
            export X_SERVER="wayland"
        elif [[ "$sessions" == "Type=x11" ]]; then
            export X_SERVER="x11"
        fi
    fi
    echo -e "[$done_format]"
}

function is_raspeberrypi_soc {
    RASPBERRYPI_MODEL="N/A"
    if [[ -f /sys/firmware/devicetree/base/model ]]; then
        if grep -q -i raspberry /sys/firmware/devicetree/base/model; then
            RASPBERRYPI_MODEL="$(tr -d '\0' < /sys/firmware/devicetree/base/model)"
        fi
    fi
    export RASPBERRYPI_MODEL
}

function get_distro {
    echo -ne "➤ Retrieving OS information... "
    if [[ -f /etc/os-release ]]; then
        KERNEL="$(uname -r)"
        PYTHON="$(python3 --version)"
        source /etc/os-release
        export DISTRO_NAME=$ID
        export DISTRO_VERSION=$VERSION
        export KERNEL PYTHON
    else
        uname
    fi
    echo -e "[$done_format]"
}

function required_packages {
    echo -ne "➤ Validating installer package requirements... "
    case $DISTRO_NAME in
    debian | ubuntu)
        apt-get update &>>"$LOG_FILE"
        apt-get install --no-install-recommends -y python3 python3-pip python3-venv whiptail expect jq git &>>"$LOG_FILE"
        ;;
    fedora | rocky)
        dnf install -y python3 python3-pip python3-virtualenv newt expect jq git &>>"$LOG_FILE"
        ;;
    esac
    echo -e "[$done_format]"
}

function create_python_venv {
    {
        echo -ne "➤ Creating Python virtualenv... "
        python3 -m venv "$VENV_PATH" &>>"$LOG_FILE"
        # shellcheck source=/dev/null
        source "$VENV_PATH/bin/activate" 
        pip3 install --upgrade pip &>>"$LOG_FILE"
        if ! grep -q "VIRTUAL_ENV=$VENV_PATH" "$RUN_AS_HOME/.bashrc" &>>"$LOG_FILE"; then
            echo "VIRTUAL_ENV=$VENV_PATH" >> "$RUN_AS_HOME/.bashrc"
        fi
        echo -e "[$done_format]"
    } 
}

function install_ansible {
    echo -ne "➤ Installing Ansible requirements in Python virtualenv... "
    pip3 install ansible PyYAML==5.3.1 &>>"$LOG_FILE"
    ansible-galaxy collection install community.docker community.general &>>"$LOG_FILE"
    echo -e "[$done_format]"
}

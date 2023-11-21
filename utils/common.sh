#!/bin/env bash
#
# Functions in this file are mostly used called by setup.sh but most of
# the exported variables are used within the Ansible playbook.

# Format the done and fail strings
done_format="\e[32mdone\e[0m"
fail_format="\e[31mfail\e[0m"

# The function exits the installer when trap detects ERR as signal.
# This is mainly used in setup.sh to handle errors during the functions
# execution.
function on_error() {
    echo -e "[$fail_format]"
    echo -e "\nPlease check $LOG_FILE for more details.\n"
    exit 1
}

# Delete installer log file if existing
# This file will be deleted at each execution of the installer.
function delete_log() {
    if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
    fi
}

# Detect information about the user running the installer
# Installer must be executed with super privileges but either
# root or sudo can run this script, we need to know whom.
function detect_user() {
    if [ "$USER_ID" -ne 0 ]; then
        echo -e "\n[$fail_format] This script must be run as root or with sudo\n"
        exit 1
    fi

    # Check for sudo or root
    if [ -n "$SUDO_USER" ]; then
        # sudo user
        export RUN_AS="$SUDO_USER"
        export RUN_AS_UID="$SUDO_UID"
        export RUN_AS_HOME="/home/$SUDO_USER"
    else
        # root user
        export RUN_AS="$USER"
        export RUN_AS_UID="$EUID"
        export RUN_AS_HOME="/$RUN_AS"
    fi
    export VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
}

# Check for which sound server is running, PulseAudio or PipeWire.
# If PulseAudio is running, the function checks to see how the PulseAudio
# service is started, is it via PulseAudio itself or via pipewire-pulse.
function detect_sound() {
    echo -ne "➤ Detecting sound server... "
    # Looking for any pulse processes
    if [[ "$(pgrep -a -f "pulse" | awk -F"/" '{ print $NF }' 2>>"$LOG_FILE")" =~ "pulse" ]]; then
        # PULSE_SERVER is required by pactl as it is executed via sudo
        # Detect if a PulseAudio socket exists either Linux or WSL2
        if [ -e "/run/user/${RUN_AS_UID}/pulse/native" ]; then
            # When running on Linux
            export PULSE_SERVER="/run/user/${RUN_AS_UID}/pulse/native"
        elif [ -e "$PULSE_SOCKET_WSL2" ]; then
            # When running on WSL2
            export PULSE_SERVER="$PULSE_SOCKET_WSL2"
        fi

        if command -v pactl &>>"$LOG_FILE"; then
            SOUND_SERVER="$(pactl info | awk -F":" '$1 ~ /Server Name/ { print $2 }' | sed 's/^ *//')"
        else
            SOUND_SERVER="PulseAudio (on PipeWire)"
        fi
        export SOUND_SERVER
    elif [ -e "$PULSE_SOCKET_WSL2" ]; then
        # This condition is only related to WSL2 as PulseServer socket will be
        # created under the /mnt/wslg/ directory.
        if command -v pactl &>>"$LOG_FILE"; then
            # PULSE_SERVER is required by pactl as it is executed via sudo
            export PULSE_SERVER="$PULSE_SOCKET_WSL2"
            SOUND_SERVER="$(pactl info | awk -F":" '$1 ~ /Server Name/ { print $2 }' | sed 's/^ *//')"
            export SOUND_SERVER
        else
            export SOUND_SERVER="N/A"
        fi
    # Looking for strictly for pipepire process
    elif [ "$(pgrep -a -f "pipewire$" | awk -F"/" '{ print $NF }' 2>>"$LOG_FILE")" == "pipewire" ]; then
        export SOUND_SERVER="PipeWire"
    else
        export SOUND_SERVER="N/A"
    fi
    echo -e "[$done_format]"
}

# Check for specific CPU instruction set in order to leverage TensorFlow
# and/or ONNXruntime. The exported variable will be used
# within the Ansible playbook to disable wake word and VAD plugins using
# these features if AVX or SIMD are not detected.
function detect_cpu_instructions() {
    echo -ne "➤ Detecting AVX/SIMD support... "
    if grep -q -i -E "avx|simd" /proc/cpuinfo; then
        export CPU_IS_CAPABLE="true"
    else
        export CPU_IS_CAPABLE="false"
    fi
    echo -e "[$done_format]"
}

# Look for existing instance of Open Voice OS
# First Docker and Podman will be checked for ovos-* and/or hivemind-*
# containers, if nothing was found then the function will check for
# the Python virtual environement.
function detect_existing_instance() {
    echo -ne "➤ Checking for existing instance... "
    if [ -n "$(docker ps -a --filter="name=ovos*|hivemind*" -q 2>>"$LOG_FILE")" ]; then
        export EXISTING_INSTANCE="true"
    elif [ -n "$(podman ps -a --filter="name=ovos*|hivemind*" -q 2>>"$LOG_FILE")" ]; then
        export EXISTING_INSTANCE="true"
    elif [ -d "${RUN_AS_HOME}/.venvs/ovos" ]; then
        export EXISTING_INSTANCE="true"
    else
        export EXISTING_INSTANCE="false"
    fi
    echo -e "[$done_format]"
}

# Check is a display server is running such as X or Wayland
# This function only works with systemd as it leveraged loginctl
# to retrieve the session type.
function detect_display() {
    echo -ne "➤ Detecting display server... "
    export DISPLAY_SERVER="N/A"
    local sessions
    sessions="$(loginctl | grep "$RUN_AS" | awk '{ print $1 }')"
    for session in $sessions; do
        session_type="$(loginctl show-session "$session" -p Type --value)"
        if [ "$session_type" == "wayland" ]; then
            export DISPLAY_SERVER="wayland"
        elif [ "$session_type" == "x11" ]; then
            export DISPLAY_SERVER="x11"
        fi
    done
    echo -e "[$done_format]"
}

# Parse /sys/firmware/devicetree/base/model file if exist and check
# for "raspberrypi" string. This will be used by the installer to
# apply the Ansible tuning tasks.
function is_raspeberrypi_soc() {
    echo -ne "➤ Checking for Raspberry Pi board... "
    RASPBERRYPI_MODEL="N/A"
    if [ -f "$DT_FILE" ]; then
        if grep -q -i raspberry "$DT_FILE"; then
            RASPBERRYPI_MODEL="$(tr -d '\0' <"$DT_FILE")"
        fi
    fi
    export RASPBERRYPI_MODEL
    echo -e "[$done_format]"
}

# Retrieve operating system information based on standard /etc/os-release
# and Python command. This is used to provide information to the user
# about the platform where the installer is running on.
function get_os_information() {
    echo -ne "➤ Retrieving OS information... "
    if [ -f "$OS_RELEASE" ]; then
        KERNEL="$(uname -r 2>>"$LOG_FILE")"
        PYTHON="$(python3 --version 2>>"$LOG_FILE")"

        # shellcheck source=/etc/os-release
        source "$OS_RELEASE"

        export DISTRO_NAME="$ID"
        export DISTRO_VERSION="$VERSION"
        export KERNEL PYTHON
    else
        # Mostly if the detected system is no a Linux OS
        uname 2>>"$LOG_FILE"
    fi
    echo -e "[$done_format]"
}

# Install packages required by the installer based on retrieved information
# from get_os_information() function. If the operating system is not supported then
# the installer will exit with a message.
function required_packages() {
    echo -ne "➤ Validating installer package requirements... "
    case $DISTRO_NAME in
    debian | ubuntu)
        apt-get update &>>"$LOG_FILE"
        apt-get install --no-install-recommends -y python3.11 python3.11-dev python3-pip python3-venv whiptail expect jq &>>"$LOG_FILE"
        ;;
    fedora)
        dnf install -y python3.11 python3.11-devel python3-pip python3-virtualenv newt expect jq &>>"$LOG_FILE"
        ;;
    rocky | centos | rhel)
        dnf install -y python3.11 python3.11-devel python3-pip newt expect jq &>>"$LOG_FILE"
        ;;
    *)
        echo -e "[$fail_format]"
        echo "Operating systemd not supported."
        exit 1
        ;;
    esac
    echo -e "[$done_format]"
}

# Create the installer Python virtual environment and update pip package.
# Permissions on the virtual environment are set to match the
# target user.
function create_python_venv() {
    echo -ne "➤ Creating installer Python virtualenv... "
    if [ ! -d "$VENV_PATH" ]; then
        python3 -m venv "$VENV_PATH" &>>"$LOG_FILE"
    fi

    # shellcheck source=/dev/null
    source "$VENV_PATH/bin/activate"

    pip3 install --upgrade pip setuptools &>>"$LOG_FILE"
    chown "$RUN_AS":"$RUN_AS" "$VENV_PATH"
    echo -e "[$done_format]"
}

# Install Ansible into the new Python virtual environment and install the
# Ansible collections required by the Ansible playbook as well. These
# collection will be installed under the /root/.ansible directory.
#
# NOTE: PyYAML is downgraded because of docker-compose Python library which
# does not support PyYAML > 5.3.1 version.
function install_ansible() {
    echo -ne "➤ Installing Ansible requirements in Python virtualenv... "
    pip3 install ansible==8.6.1 PyYAML==5.3.1 &>>"$LOG_FILE"
    ansible-galaxy collection install -r ansible/requirements.yml &>>"$LOG_FILE"
    echo -e "[$done_format]"
}

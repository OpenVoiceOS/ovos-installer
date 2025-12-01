#!/bin/env bash
set -euo pipefail
#
# Functions in this file are mostly called by setup.sh but most of
# the exported variables are consumed within the Ansible playbook.

done_format="\e[32mdone\e[0m"
fail_format="\e[31mfail\e[0m"

# This function asks for user agreement on uploading the content of
# ovos-installer.log on https://paste.uoi.io. Without the user
# agreement this could lead to security infringement.
function ask_optin() {
    while true; do
        read -rp "Upload the log on ${PASTE_URL} website? (yes/no) " yn
        case $yn in
        [Yy]*)
            return 0
            ;;
        [Nn]*)
            printf '%s\n' "Unable to continue the process, please check $LOG_FILE for more details."
            exit 1
            ;;
        *) printf '%s\n' "Please answer (y)es or (n)o." ;;
        esac
    done
}

# The function exits the installer when trap detects ERR as signal.
# This is mainly used in setup.sh to handle errors during the functions
# execution.
function on_error() {
    echo -e "[$fail_format]"
    ask_optin
    if [ -n "${ANSIBLE_LOG_FILE:-}" ] && [ -f "$ANSIBLE_LOG_FILE" ]; then
        cat "$ANSIBLE_LOG_FILE" >>"$LOG_FILE"
    fi
    if command -v curl >/dev/null 2>&1; then
        debug_url="$(curl -sSf -m 10 -F 'content=<-' "${PASTE_URL}/api/" <"$LOG_FILE" || true)"
    fi
    printf '\n%s\n' "➤ Unable to finalize the process, please check $LOG_FILE for more details."
    if [ -n "${debug_url:-}" ]; then
        printf '%s\n' "➤ Please share this URL with us $debug_url"
    else
        printf '%s\n' "➤ Failed to upload logs automatically. Please attach $LOG_FILE."
    fi
    exit "${EXIT_FAILURE}"
}

# Delete installer log file if existing from previous run.
# This file will be deleted at each execution of the installer.
function delete_log() {
    if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
    fi
}

# Detect information about the user running the installer.
# Installer must be executed with super privileges but either
# "root" or "sudo" can run this script, we need to know whom.
function detect_user() {
    if [ "${USER_ID:-$(id -u)}" -ne 0 ]; then
        echo -e "[$fail_format] This script must be run as root (not recommended) or with sudo"
        exit "${EXIT_PERMISSION_DENIED}"
    fi

    if [ -n "${SUDO_USER:-}" ]; then
        export RUN_AS="${SUDO_USER}"
        export RUN_AS_UID="${SUDO_UID:-$(id -u "${SUDO_USER}")}"
    else
        if [ -t 0 ]; then
            while true; do
                printf '%s\n' "Best practices don't recommend running the installer as root user!"
                read -rp "Do you really want to continue as you will be on your own? (yes/no) " yn
                case "${yn}" in
                [Yy]*)
                    return 0
                    ;;
                [Nn]*)
                    printf '\n%s\n' "Smart choice! Exiting the installer..."
                    exit 1
                    ;;
                *) printf '%s\n' "Please answer (y)es or (n)o." ;;
                esac
            done
        else
            printf '%s\n' "Non-interactive mode detected. Exiting as root user is not recommended."
            exit "${EXIT_PERMISSION_DENIED}"
        fi
        export RUN_AS="${USER}"
        export RUN_AS_UID="${EUID}"
    fi
    RUN_AS_HOME=$(eval echo ~"${RUN_AS}")
    export RUN_AS_HOME
    export VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
}

# Detect which sound server is running (if running), PulseAudio or PipeWire.
# If PulseAudio is running, the function checks how the PulseAudio
# service is started, whether via PulseAudio itself or via pipewire-pulse.
#
# This function sets the following environment variables:
#   - PULSE_SERVER: Path to PulseAudio socket if detected
#   - PULSE_COOKIE: Path to PulseAudio cookie if detected
#   - SOUND_SERVER: Name of detected sound server or "N/A"
#
# Dependencies:
#   - RUN_AS_UID: Must be set by detect_user()
#   - RUN_AS_HOME: Must be set by detect_user()
#
# Returns:
#   Always succeeds, sets SOUND_SERVER to "N/A" if no server detected
function detect_sound() {
    printf '%s' "➤ Detecting sound server... "
    local pulse_processes
    pulse_processes="$( (pgrep -a -f "pulse" 2>>"$LOG_FILE" || true) | awk -F"/" '{ print $NF }' )"
    if [[ "$pulse_processes" =~ "pulse" ]]; then
        # PULSE_SERVER is required by pactl as it is executed via sudo
        # Detect if a PulseAudio socket exists either Linux or WSL2
        if [ -S "/run/user/${RUN_AS_UID}/pulse/native" ] && [ ! -S "$PULSE_SOCKET_WSL2" ]; then
            export PULSE_SERVER="/run/user/${RUN_AS_UID}/pulse/native"
            export PULSE_COOKIE="${RUN_AS_HOME}/.config/pulse/cookie"
        elif [ -S "$PULSE_SOCKET_WSL2" ]; then
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
            export PULSE_SERVER="$PULSE_SOCKET_WSL2"
            SOUND_SERVER="$(pactl info | awk -F":" '$1 ~ /Server Name/ { print $2 }' | sed 's/^ *//')"
            export SOUND_SERVER
        else
            export SOUND_SERVER="N/A"
        fi
    # Looking for pipewire process
    elif [ "$( (pgrep -a -f "pipewire$" 2>>"$LOG_FILE" || true) | awk -F"/" '{ print $NF }' )" == "pipewire" ]; then
        export SOUND_SERVER="PipeWire"
    else
        export SOUND_SERVER="N/A"
    fi
    echo -e "[$done_format]"
}

# Check for specific CPU instruction set in order to leverage TensorFlow
# and/or ONNXruntime. The exported variable will be used within the
# Ansible playbook to disable certain wake words and VAD plugin requiring
# these features if AVX2 or SIMD are not detected.
function detect_cpu_instructions() {
    printf '%s' "➤ Detecting AVX2/SIMD support... "
    if grep -q -i -E "avx2|simd" /proc/cpuinfo; then
        export CPU_IS_CAPABLE="true"
    else
        export CPU_IS_CAPABLE="false"
    fi
    echo -e "[$done_format]"
}

# Look for existing or partial instance of Open Voice OS.
# First Docker and Podman will be checked for ovos-* and/or hivemind-*
# containers, if nothing was found then the function will check for
# the Python virtual environment.
function detect_existing_instance() {
    printf '%s' "➤ Checking for existing instance... "
    if [ -n "$(docker ps -a --filter="name=ovos_core|ovos_messagebus|hivemind*" -q 2>>"$LOG_FILE")" ]; then
        export EXISTING_INSTANCE="true"
        export INSTANCE_TYPE="containers"
    elif [ -n "$(podman ps -a --filter="name=ovos_core|ovos_messagebus|hivemind*" -q 2>>"$LOG_FILE")" ]; then
        export EXISTING_INSTANCE="true"
        export INSTANCE_TYPE="containers"
    elif [ -d "${RUN_AS_HOME}/.venvs/ovos" ]; then
        export EXISTING_INSTANCE="true"
        export INSTANCE_TYPE="virtualenv"
    else
        export EXISTING_INSTANCE="false"
    fi
    echo -e "[$done_format]"
}

# Check is a display server is running such as X or Wayland
# This function only works with systemd as it leveraged loginctl
# to retrieve the session type.
function detect_display() {
    printf '%s' "➤ Detecting display server... "
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

# Parse /sys/firmware/devicetree/base/model file if it exists and check
# for "raspberrypi" string.
function is_raspeberrypi_soc() {
    printf '%s' "➤ Checking for Raspberry Pi board... "
    RASPBERRYPI_MODEL="N/A"
    if [ -f "$DT_FILE" ]; then
        if grep -q -i raspberry "$DT_FILE"; then
            RASPBERRYPI_MODEL="$(tr -d '\0' <"$DT_FILE")"

            # Disable wlan0 power management to avoid potential network
            # connectivity issue during the installation process. This is
            # properly handled by Ansible during the playbook execution.
            if command -v iw &>>"$LOG_FILE"; then
                iw "$WLAN_INTERFACE" set power_save off
            fi
        fi
    fi
    export RASPBERRYPI_MODEL
    echo -e "[$done_format]"
}

# Retrieve operating system information based on standard /etc/os-release
# and Python command. This is used to display information to the user
# about the platform where the installer is running on and where OVOS is
# going to be installed.
function get_os_information() {
    printf '%s' "➤ Retrieving OS information... "
    if [ -f "$OS_RELEASE" ]; then
        ARCH="$(uname -m 2>>"$LOG_FILE")"
        KERNEL="$(uname -r 2>>"$LOG_FILE")"
        PYTHON="$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[0:2])))' 2>>"$LOG_FILE")"

        # shellcheck source=/etc/os-release
        source "$OS_RELEASE"

        export DISTRO_NAME="${ID:-unknown}"
        export DISTRO_VERSION_ID="${VERSION_ID:-}"
        export DISTRO_VERSION="${VERSION:-}"
        export ARCH KERNEL PYTHON

        # For debug purpose only
        echo ["$ARCH", "$KERNEL", "$PYTHON", "$DISTRO_NAME", "$DISTRO_VERSION_ID"] >>"$LOG_FILE"
    else
        # Mostly if the detected system is no a Linux OS
        uname 2>>"$LOG_FILE"
    fi
    echo -e "[$done_format]"
}

# Validate the default Python version before creating the virtualenv.
# onnxruntime is currently incompatible with Python 3.14, so abort early.
function check_python_compatibility() {
    printf '%s' "➤ Validating default Python version... "
    local python_version="${PYTHON:-}"

    if [ -z "$python_version" ]; then
        echo -e "[$fail_format]"
        echo "Unable to determine the default Python version." | tee -a "$LOG_FILE"
        exit "${EXIT_MISSING_DEPENDENCY}"
    fi

    if [ "$python_version" == "3.14" ]; then
        echo -e "[$fail_format]"
        echo "Python $python_version is not supported because onnxruntime is not yet compatible with it." | tee -a "$LOG_FILE"
        exit "${EXIT_MISSING_DEPENDENCY}"
    fi

    echo -e "[$done_format]"
}

# Install packages for Debian-based distributions
function install_debian_packages() {
    local extra_packages=("$@")
    UPDATE=1 apt_ensure python3 python3-dev python3-pip python3-venv whiptail expect jq "${extra_packages[@]}" &>>"$LOG_FILE"
}

# Install packages for Fedora-based distributions
function install_fedora_packages() {
    local extra_packages=("$@")
    dnf install -y python3 python3-devel python3-pip python3-virtualenv python3-libdnf5 newt expect jq "${extra_packages[@]}" &>>"$LOG_FILE"
}

# Install packages for Red Hat-based distributions
function install_rhel_packages() {
    local extra_packages=("$@")
    dnf install -y python3 python3-devel python3-pip newt expect jq "${extra_packages[@]}" &>>"$LOG_FILE"
}

# Install packages for openSUSE distributions
function install_opensuse_packages() {
    local extra_packages=("$@")
    zypper install --no-recommends -y python3 python3-devel python3-pip python3-rpm newt expect jq "${extra_packages[@]}" &>>"$LOG_FILE"
}

# Install packages for Arch-based distributions
function install_arch_packages() {
    local extra_packages=("$@")
    pacman -Sy --noconfirm python python-pip python-virtualenv libnewt expect jq "${extra_packages[@]}" &>>"$LOG_FILE"
}

# Install packages required by the installer based on retrieved information
# from get_os_information() function. If the operating system is not supported then
# the installer will exit with a message.
#
# This function validates that required environment variables are set and
# delegates package installation to distro-specific functions.
#
# Dependencies:
#   - DISTRO_NAME: Must be set by get_os_information()
#   - RASPBERRYPI_MODEL: Optional, set by is_raspeberrypi_soc()
#
# Returns:
#   0 on success, exits with EXIT_OS_NOT_SUPPORTED for unsupported distros
function required_packages() {
    # Input validation
    if [ -z "${DISTRO_NAME:-}" ]; then
        echo "Error: DISTRO_NAME is not set. Run get_os_information() first." >&2
        exit "${EXIT_MISSING_DEPENDENCY}"
    fi

    printf '%s' "➤ Validating installer package requirements... "
    # Add extra packages if a Raspberry Pi board is detected
    local extra_packages=()
    if [ "${RASPBERRYPI_MODEL:-N/A}" != "N/A" ]; then
        extra_packages+=("i2c-tools")
        extra_packages+=("iw")
        extra_packages+=("libhidapi-libusb0")
    fi

    case "${DISTRO_NAME}" in
    debian | ubuntu | raspbian | linuxmint | zorin | neon | pop)
        install_debian_packages "${extra_packages[@]}"
        ;;
    fedora)
        install_fedora_packages "${extra_packages[@]}"
        ;;
    almalinux | rocky | centos)
        install_rhel_packages "${extra_packages[@]}"
        ;;
    opensuse-tumbleweed | opensuse-leap | opensuse-slowroll)
        install_opensuse_packages "${extra_packages[@]}"
        ;;
    arch | manjaro | endeavouros)
        install_arch_packages "${extra_packages[@]}"
        ;;
    *)
        echo -e "[$fail_format]"
        echo "Operating system not supported." | tee -a "${LOG_FILE}"
        exit "${EXIT_OS_NOT_SUPPORTED}"
        ;;
    esac
    echo -e "[$done_format]"
}

# Create the installer Python virtual environment and update pip and
# setuptools package.Permissions on the virtual environment are set
# to match the target user.
function create_python_venv() {
    printf '%s' "➤ Creating installer Python virtualenv... "

    # Make sure Python version is higher then 3.8.
    if [ "$(ver "$PYTHON")" -lt "$(ver 3.9)" ]; then
        echo "python $PYTHON is not supported" &>>"$LOG_FILE"
        on_error
    fi

    # Disable https://www.piwheels.org/simple when aarch64 CPU architecture
    # or Raspberry Pi 5 board are detected.
    if [ -f /etc/pip.conf ]; then
        if [ "$ARCH" == "aarch64" ] || [[ "$RASPBERRYPI_MODEL" != *"Raspberry Pi 5"* ]]; then
            sed -e '/extra-index/ s/^#*/#/g' -i /etc/pip.conf &>>"$LOG_FILE"
        fi
    fi

    if [ -d "$VENV_PATH" ]; then
        if [ "$REUSE_CACHED_ARTIFACTS" != "true" ]; then
            # Make sure everything is clean before starting.
            rm -rf "$VENV_PATH" /root/.ansible &>>"$LOG_FILE"
        fi
    fi

    python3 -m venv "$VENV_PATH" &>>"$LOG_FILE"

    # shellcheck source=/dev/null
    source "$VENV_PATH/bin/activate"

    if [ "$USE_UV" == "true" ]; then
        export PIP_COMMAND="uv pip"
        if ! command -v uv &>>"$LOG_FILE"; then
            pip3 install --no-cache-dir "uv>=0.4.10" &>>"$LOG_FILE"
        fi
    else
        export PIP_COMMAND="pip3"
    fi

    $PIP_COMMAND install --no-cache-dir --upgrade pip setuptools &>>"$LOG_FILE"
    chown "$RUN_AS":"$(id -ng "$RUN_AS" 2>>"$LOG_FILE" || echo "$RUN_AS")" "$VENV_PATH" "${RUN_AS_HOME}/.venvs" &>>"$LOG_FILE"
    unset -f ansible-galaxy pip3
    echo -e "[$done_format]"
}

# Install Ansible into the new Python virtual environment and install the
# Ansible's collections required by the Ansible playbook as well. These
# collections will be installed under the /root/.ansible directory.
function install_ansible() {
    printf '%s' "➤ Installing Ansible requirements in Python virtualenv... "
    ANSIBLE_VERSION="10.7.0"
    [ "$(ver "$PYTHON")" -lt "$(ver 3.10)" ] && ANSIBLE_VERSION="8.7.0"
    $PIP_COMMAND install --no-cache-dir ansible=="$ANSIBLE_VERSION" docker==7.1.0 requests==2.32.3 &>>"$LOG_FILE"
    ansible-galaxy collection install -r ansible/requirements.yml &>>"$LOG_FILE"
    echo -e "[$done_format]"
}

# Downloads the yq tool from GitHub to parse YAML scenario file.
# The binary will be downloaded based on the found operating system and CPU
# architecture.
function download_yq() {
    if [ -f "$YQ_BINARY_PATH" ]; then
        rm "$YQ_BINARY_PATH"
    fi
    # Retrieve kernel information and map it to a more generic CPU architecture
    local arch
    local kernel
    arch="$(echo "$ARCH" | sed s/aarch64/arm64/g | sed s/x86_64/amd64/g | sed s/armv6l/386/g | sed s/armv7l/386/g 2>>"$LOG_FILE")"
    kernel="$(uname -s 2>>"$LOG_FILE")"

    curl -s -f -L "$YQ_URL/yq_${kernel,,}_$arch" -o "$YQ_BINARY_PATH" &>>"$LOG_FILE"
    chmod 0755 "$YQ_BINARY_PATH" &>>"$LOG_FILE"
}

# Search for a scenario.yaml file. This file will be used for non-interactive
# installation like when running within a CI or when industrial deployments
# are required.
function detect_scenario() {
    printf '%s' "➤ Looking for automated scenario... "
    SCENARIO_PATH="$RUN_AS_HOME/.config/ovos-installer/$SCENARIO_NAME"
    export SCENARIO_FOUND="false"
    if [ -f "$SCENARIO_PATH" ]; then
        # Make sure scenario has a valid YAML syntax
        download_yq
        "$YQ_BINARY_PATH" "$SCENARIO_PATH" &>>"$LOG_FILE"

        SCENARIO_NOT_SUPPORTED="false"
        # shellcheck source=scenario.sh
        source utils/scenario.sh

        # Check scenario status
        if [ "$SCENARIO_NOT_SUPPORTED" == "true" ]; then
            echo "scenario not supported" &>>"$LOG_FILE"
            on_error
        fi

        export SCENARIO_FOUND="true"

        if [ -f "$YQ_BINARY_PATH" ]; then
            rm "$YQ_BINARY_PATH"
        fi
    fi
    echo -e "[$done_format]"
}

# This function checks if element exists within a Bash array.
# The function takes two arguments:
#  1. The Bash array
#  2. The element to find
# Credit: https://raymii.org/s/snippets/Bash_Bits_Check_If_Item_Is_In_Array.html
function in_array() {
    local haystack="${1}[@]"
    local needle="${2}"
    for element in "${!haystack}"; do
        if [ "${element}" == "${needle}" ]; then
            return 0
        fi
    done
    # Call on_error() function if option is not supported
    echo "$needle is an unsupported option" &>>"$LOG_FILE"
    on_error
}

# This function validates basic requirements for Windows WSL2 such as systemd
# handles the boot process, etc...
function wsl2_requirements() {
    if [[ "$KERNEL" == *"microsoft"* ]]; then
        printf '%s' "➤ Validating WSL2 requirements... "
        if ! grep -q "systemd=true" "$WSL_FILE" &>>"$LOG_FILE"; then
            echo "systemd=true must be added to $WSL_FILE" &>>"$LOG_FILE"
            return 1
        fi
        echo -e "[$done_format]"
    fi
}

# This is a helper to strip the point from semantic versioning such as 3.9 or
# 6.5.3. Mostly useful when comparing Python or kernel version.
function ver() {
    # shellcheck disable=SC2046
    printf "%03d" $(echo "$1" | tr '.' ' ')
}

# Check if a specific hexadecimal address exists on the I2C bus.
# Takes an argument like "2f" which is converted to "0x2f".
# Only used when a Raspberry Pi board is detected.
function i2c_get() {
    if i2cdetect -y -a "$I2C_BUS" "0x$1" "0x$1" 2>>"$LOG_FILE" | grep -Eq "$1|UU"; then
        return 0
    fi
    return 1
}

# Scan the I2C bus to find any devices supported by the installer.
# This function will only run if a Raspberry Pi board is detected.
function i2c_scan() {
    if [ "$RASPBERRYPI_MODEL" != "N/A" ]; then
        printf '%s' "➤ Scan I2C bus for hardware auto-detection..."

        # Load I2C requirements if not already, nothing persistent here as
        # it will be handled later by the Ansible playbook.
        if ! dtparam -l | grep -q i2c_arm=on; then
            dtparam -v i2c_arm=on &>>"$LOG_FILE"
        fi
        if ! lsmod | grep -q i2c_dev; then
            modprobe -v i2c-dev &>>"$LOG_FILE"
        fi

        for device in "${!SUPPORTED_DEVICES[@]}"; do
            address="${SUPPORTED_DEVICES[$device]}"
            if i2c_get "$address"; then
                if [ "$device" == "atmega328p" ]; then
                    detect_mark1_device
                elif [ "$device" == "tas5806" ]; then
                    detect_devkit_device
                else
                    DETECTED_DEVICES+=("$device")
                fi
            fi
        done
        echo -e "[$done_format]"
    fi
}

# Downloads avrdude binary with libgpiod support from
# https://artifacts.smartgic.io. Once downloaded, a custom avrduderc will
# be created with the Mark 1 required pinout. This binary will only be
# downloaded when I2C 1a address (UU reserved address) and Raspberry Pi
# board are detected.
function setup_avrdude() {
    if [ -f "$AVRDUDE_BINARY_PATH" ]; then
        rm "$AVRDUDE_BINARY_PATH"
    fi

    curl -s -f -L --insecure "$AVRDUDE_BINARY_URL" -o "$AVRDUDE_BINARY_PATH" &>>"$LOG_FILE"
    chmod 0755 "$AVRDUDE_BINARY_PATH" &>>"$LOG_FILE"

    cat <<EOF >"$RUN_AS_HOME/.avrduderc"
# Mark 1 pinout
programmer
  id               = "linuxgpio_rpi";
  desc             = "Raspberry Pi 3B libgpiod bitbang (BCM: RST=22,SCK=27,SDO=24,SDI=17)";
  type             = "linuxgpio";
  connection_type  = linuxgpio;
  prog_modes       = PM_ISP;

  reset = 22;   # BCM numbers
  sck   = 27;
  sdo   = 24;   # MOSI
  sdi   = 17;   # MISO
;
EOF
    chown "$RUN_AS:$(id -ng "$RUN_AS")" "$RUN_AS_HOME/.avrduderc" &>>"$LOG_FILE"
    curl -s -f -L --insecure "$AVRDUDE_CONFIG_URL" -o "$AVRDUDE_CONFIG_PATH" &>>"$LOG_FILE"
}

# This function retrieves the atmega328p signature when present. If the
# signature matches a specific value then it means that a Mark 1 device
# is detected.
# This function is only triggered when a I2C reserved device is detected.
function detect_mark1_device() {
    setup_avrdude
    atmega328p="$(avrdude -C +"$RUN_AS_HOME"/.avrduderc -p atmega328p -c linuxgpio -U signature:r:-:i -F 2>>"$LOG_FILE" | head -1)"
    if [ "$atmega328p" == "$ATMEGA328P_SIGNATURE" ]; then
        DETECTED_DEVICES+=("atmega328p")
    fi
}

# This function checks if attiny1614 I2C device is present, this is only
# triggered when a tas5806 I2C device is detected.
function detect_devkit_device() {
    if i2c_get "${SUPPORTED_DEVICES["attiny1614"]}"; then
        DETECTED_DEVICES+=("attiny1614")
    fi
    # If attiny1614 is not detected then this is a Mark II device and not
    # a DevKit device so we force back the DETECTED_DEVICES variable
    # to tas5806.
    DETECTED_DEVICES+=("tas5806")
}

# Checks to see if apt-based packages are installed and installs them if needed.
# The main reason to use this over normal apt install is that it avoids sudo if
# we already have all requested packages.
# Args:
#     *ARGS : one or more requested packages
# Environment:
#     UPDATE : if this is populated also runs and apt update
# Example:
#     apt_ensure git curl htop
function apt_ensure() {
    # Note the $@ is not actually an array, but we can convert it to one
    # https://linuxize.com/post/bash-functions/#passing-arguments-to-bash-functions
    ARGS=("$@")
    MISS_PKGS=()
    HIT_PKGS=()
    _SUDO=""
    if [ "$(whoami)" != "root" ]; then
        # Only use the sudo command if we need it (i.e. we are not root)
        _SUDO="sudo "
    fi
    for PKG_NAME in "${ARGS[@]}"; do
        # Check if the package is already installed or not
        if dpkg-query -W -f='${Status}' "$PKG_NAME" 2>/dev/null | grep -q "install ok installed"; then
            echo "Already have PKG_NAME='$PKG_NAME'"
            HIT_PKGS+=("$PKG_NAME")
        else
            echo "Do not have PKG_NAME='$PKG_NAME'"
            MISS_PKGS+=("$PKG_NAME")
        fi
    done
    # Install the packages if any are missing
    if [ "${#MISS_PKGS[@]}" -gt 0 ]; then
        if [ "${UPDATE}" != "" ]; then
            $_SUDO apt update -y
        fi
        DEBIAN_FRONTEND=noninteractive $_SUDO apt install --no-install-recommends -y "${MISS_PKGS[@]}"
    else
        echo "No missing packages"
    fi
}

# This function ensures the existence and proper configuration of a
# local state directory for the OVOS environment. It sets up a
# specific directory structure and prepares an installer state file for use.
function state_directory() {
    OVOS_LOCAL_STATE_DIRECTORY="$RUN_AS_HOME/.local/state/ovos"
    export INSTALLER_STATE_FILE="$OVOS_LOCAL_STATE_DIRECTORY/installer.json"
    if [ ! -d "$OVOS_LOCAL_STATE_DIRECTORY" ]; then
        mkdir -p "$OVOS_LOCAL_STATE_DIRECTORY" &>>"$LOG_FILE"
        chown -R "$RUN_AS":"$(id -ng "$RUN_AS")" "$RUN_AS_HOME/.local/state" &>>"$LOG_FILE"

    fi
    if [ -f "$INSTALLER_STATE_FILE" ]; then
        [ -s "$INSTALLER_STATE_FILE" ] || rm "$INSTALLER_STATE_FILE" &>>"$LOG_FILE"
    fi
}

#!/bin/env bash
#
# Functions in this file are mostly called by setup.sh but most of
# the exported variables are consumed within the Ansible playbook.

# Format the "done" and "fail" strings
done_format="\e[32mdone\e[0m"
fail_format="\e[31mfail\e[0m"

# The function exits the installer when trap detects ERR as signal.
# This is mainly used in setup.sh to handle errors during the functions
# execution.
function on_error() {
    debug_url="$(curl -sF 'content=<-' https://dpaste.com/api/v2/ <"$LOG_FILE")"
    echo -e "[$fail_format]"
    echo -e "\nUnable to continue the process, please check $LOG_FILE for more details."
    echo -e "Please share this URL with us $debug_url"
    exit 1
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
    if [ "$USER_ID" -ne 0 ]; then
        echo -e "[$fail_format] This script must be run as root or with sudo\n"
        exit 1
    fi

    # Check for sudo or root user
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

# Detect which sound server is running (if running), PulseAudio or PipeWire.
# If PulseAudio is running, the function checks to see how the PulseAudio
# service is started, is it via PulseAudio itself or via pipewire-pulse.
function detect_sound() {
    echo -ne "➤ Detecting sound server... "
    # Looking for any pulse processes
    if [[ "$(pgrep -a -f "pulse" | awk -F"/" '{ print $NF }' 2>>"$LOG_FILE")" =~ "pulse" ]]; then
        # PULSE_SERVER is required by pactl as it is executed via sudo
        # Detect if a PulseAudio socket exists either Linux or WSL2
        if [ -S "/run/user/${RUN_AS_UID}/pulse/native" ] && [ ! -S "$PULSE_SOCKET_WSL2" ]; then
            # When running on Linux
            export PULSE_SERVER="/run/user/${RUN_AS_UID}/pulse/native"
            export PULSE_COOKIE="${RUN_AS_HOME}/.config/pulse/cookie"
        elif [ -S "$PULSE_SOCKET_WSL2" ]; then
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
# and/or ONNXruntime. The exported variable will be used within the
# Ansible playbook to disable certain wake words and VAD plugin requiring
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

# Look for existing or partial instance of Open Voice OS.
# First Docker and Podman will be checked for ovos-* and/or hivemind-*
# containers, if nothing was found then the function will check for
# the Python virtual environement.
function detect_existing_instance() {
    echo -ne "➤ Checking for existing instance... "
    if [ -n "$(docker ps -a --filter="name=ovos*|hivemind*" -q 2>>"$LOG_FILE")" ]; then
        export EXISTING_INSTANCE="true"
        export INSTANCE_TYPE="containers"
    elif [ -n "$(podman ps -a --filter="name=ovos*|hivemind*" -q 2>>"$LOG_FILE")" ]; then
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

# Parse /sys/firmware/devicetree/base/model file if it exists and check
# for "raspberrypi" string.
function is_raspeberrypi_soc() {
    echo -ne "➤ Checking for Raspberry Pi board... "
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
# gonna be installed.
function get_os_information() {
    echo -ne "➤ Retrieving OS information... "
    if [ -f "$OS_RELEASE" ]; then
        ARCH="$(uname -m 2>>"$LOG_FILE")"
        KERNEL="$(uname -r 2>>"$LOG_FILE")"
        PYTHON="$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[0:2])))' 2>>"$LOG_FILE")"

        # shellcheck source=/etc/os-release
        source "$OS_RELEASE"

        export DISTRO_NAME="$ID"
        export DISTRO_VERSION_ID="$VERSION_ID"
        export DISTRO_VERSION="$VERSION"
        export ARCH KERNEL PYTHON
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
    # Add extra packages if a Raspberry Pi board is detected
    declare extra_packages
    if [ "$RASPBERRYPI_MODEL" != "N/A" ]; then
        extra_packages+=("i2c-tools")
        extra_packages+=("iw")
    fi

    case "$DISTRO_NAME" in
    debian | ubuntu | raspbian | linuxmint | zorin)
        apt-get update &>>"$LOG_FILE"
        apt-get install --no-install-recommends -y python3 python3-dev python3-pip python3-venv whiptail expect jq "${extra_packages[@]}" &>>"$LOG_FILE"
        ;;
    fedora)
        dnf install -y python3 python3-devel python3-pip python3-virtualenv newt expect jq "${extra_packages[@]}" &>>"$LOG_FILE"
        ;;
    almalinux | rocky | centos)
        dnf install -y python3 python3-devel python3-pip newt expect jq "${extra_packages[@]}" &>>"$LOG_FILE"
        ;;
    opensuse-tumbleweed | opensuse-leap | opensuse-slowroll)
        zypper install --no-recommends -y python3 python3-devel python3-pip python3-rpm newt expect jq "${extra_packages[@]}" &>>"$LOG_FILE"
        ;;
    arch | manjaro | endeavouros)
        pacman -Sy --noconfirm python python-pip python-virtualenv libnewt expect jq "${extra_packages[@]}" &>>"$LOG_FILE"
        ;;
    *)
        echo -e "[$fail_format]"
        echo "Operating system not supported." | tee -a "$LOG_FILE"
        exit 1
        ;;
    esac
    echo -e "[$done_format]"
}

# Create the installer Python virtual environment and update pip and
# setuptools package.Permissions on the virtual environment are set
# to match the target user.
function create_python_venv() {
    echo -ne "➤ Creating installer Python virtualenv... "
    # Disable https://www.piwheels.org/simple when aarch64 CPU architecture
    # or Raspberry Pi 5 board are detected.
    if [ -f /etc/pip.conf ]; then
        if [ "$ARCH" == "aarch64" ] || [[ "$RASPBERRYPI_MODEL" != *"Raspberry Pi 5"* ]]; then
            sed -e '/extra-index/ s/^#*/#/g' -i /etc/pip.conf &>>"$LOG_FILE"
        fi
    fi

    if [ -d "$VENV_PATH" ]; then
        # Make sure everything is clean before starting.
        rm -rf "$VENV_PATH" /root/.ansible &>>"$LOG_FILE"
    fi
    python3 -m venv "$VENV_PATH" &>>"$LOG_FILE"

    # shellcheck source=/dev/null
    source "$VENV_PATH/bin/activate"

    pip3 install --upgrade pip setuptools &>>"$LOG_FILE"
    chown "$RUN_AS":"$(id -ng "$RUN_AS")" "$VENV_PATH" "${RUN_AS_HOME}/.venvs" &>>"$LOG_FILE"
    echo -e "[$done_format]"
}

# Install Ansible into the new Python virtual environment and install the
# Ansible's collections required by the Ansible playbook as well. These
# collections will be installed under the /root/.ansible directory.
function install_ansible() {
    echo -ne "➤ Installing Ansible requirements in Python virtualenv... "
    ANSIBLE_VERSION="9.2.0"
    [ "$(ver "$PYTHON")" -lt "$(ver 3.10)" ] && ANSIBLE_VERSION="8.7.0"
    pip3 install ansible=="$ANSIBLE_VERSION" docker==7.1.0 requests==2.31.0 &>>"$LOG_FILE"
    ansible-galaxy collection install -r ansible/requirements.yml &>>"$LOG_FILE"
    echo -e "[$done_format]"
}

# Downloads the yq tool from GitHub to parse YAML scenerio file.
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
    echo -ne "➤ Looking for automated scenario... "
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
        echo -ne "➤ Validating WSL2 requirements... "
        if ! grep -q "systemd=true" "$WSL_FILE" &>>"$LOG_FILE"; then
            echo "systemd=true must be added to $WSL_FILE" &>>"$LOG_FILE"
            return 1
        fi
        echo -e "[$done_format]"
    fi
}

# This is a helper to strip the point from sementic versioning such as 3.9 or
# 6.5.3. Mostly useful when comparing Python or kernel version.
function ver() {
    # shellcheck disable=SC2046
    printf "%03d" $(echo "$1" | tr '.' ' ')
}

# Check if a specific hexacidemal address exists on the I2C bus.
# This function takes an argument like "2f", this will be converted
# to "0x2f".
# It will be only used when a Raspberry Pi board is detected.
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
        echo -ne "➤ Scan I2C bus for hardware auto-detection..."

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

    curl -s -f -L "$AVRDUDE_BINARY_URL" -o "$AVRDUDE_BINARY_PATH" &>>"$LOG_FILE"
    chmod 0755 "$AVRDUDE_BINARY_PATH" &>>"$LOG_FILE"

    cat <<EOF >"$RUN_AS_HOME/.avrduderc"
    # Mark 1 pinout
    programmer
      id                     = "linuxgpio";
      desc                   = "Use the Linux sysfs interface to bitbang GPIO lines";
      type                   = "linuxgpio";
      connection_type        = linuxgpio;
      prog_modes             = PM_ISP;
      reset                  = 22;
      sck                    = 27;
      sdo                    = 24;
      sdi                    = 17;
    ;
EOF
    chown "$RUN_AS:$(id -ng "$RUN_AS")" "$RUN_AS_HOME/.avrduderc" &>>"$LOG_FILE"
    curl -s -f -L "$AVRDUDE_CONFIG_URL" -o "$AVRDUDE_CONFIG_PATH" &>>"$LOG_FILE"
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

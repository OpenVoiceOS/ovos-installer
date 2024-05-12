#!/bin/env bash

export ATMEGA328P_SIGNATURE=":030000001E950F3B"
export AVRDUDE_BINARY_PATH=/usr/local/bin/avrdude
export AVRDUDE_BINARY_URL="https://artifacts.smartgic.io/avrdude/avrdude-aarch64"
export AVRDUDE_CONFIG_PATH=/usr/local/etc/avrdude.conf
export AVRDUDE_CONFIG_URL="https://artifacts.smartgic.io/avrdude/avrdude.conf"
declare -a DETECTED_DEVICES
export DETECTED_DEVICES
export DT_FILE=/sys/firmware/devicetree/base/model
export I2C_BUS="1"
export INSTALLER_VENV_NAME="ovos-installer"
export LOG_FILE=/var/log/ovos-installer.log
export MAX_PYTHON_VERSION="3.11"
export NEWT_COLORS="
    root=white,black
    border=black,lightgray
    window=lightgray,lightgray
    shadow=black,gray
    title=red,lightgray
    button=black,cyan
    actbutton=white,cyan
    compactbutton=black,lightgray
    checkbox=black,lightgray
    actcheckbox=lightgray,cyan
    entry=black,lightgray
    disentry=gray,lightgray
    label=black,lightgray
    listbox=black,lightgray
    actlistbox=black,cyan
    sellistbox=lightgray,black
    actsellistbox=lightgray,black
    textbox=black,lightgray
    acttextbox=black,cyan
    emptyscale=,gray
    fullscale=,cyan
    helpline=white,black
    roottext=lightgrey,black
"
export OS_RELEASE=/etc/os-release
export PULSE_SOCKET_WSL2=/mnt/wslg/PulseServer
export REBOOT_FILE_PATH=/tmp/ovos.reboot
declare -ra SCENARIO_ALLOWED_OPTIONS=(features channel share_telemetry profile method uninstall rapsberry_pi_tuning hivemind)
export SCENARIO_ALLOWED_OPTIONS
declare -ra SCENARIO_ALLOWED_FEATURES=(skills gui)
export SCENARIO_ALLOWED_FEATURES
declare -ra SCENARIO_ALLOWED_HIVEMIND_OPTIONS=(host port key password)
export SCENARIO_ALLOWED_HIVEMIND_OPTIONS
export SCENARIO_NAME="scenario.yaml"
export SCENARIO_PATH=""
declare -rA SUPPORTED_DEVICES=(
    ["atmega328p"]="1a" #https://www.microchip.com/en-us/product/atmega328p
    ["attiny1614"]="04" #https://www.microchip.com/en-us/product/attiny1614
    ["tas5806"]="2f" #https://www.ti.com/product/TAS5806MD
)
export SUPPORTED_DEVICES
export TUI_WINDOW_HEIGHT="35"
export TUI_WINDOW_WIDTH="90"
export USER_ID="$EUID"
export WLAN_INTERFACE="wlan0"
export WSL_FILE=/etc/wsl.conf
export YQ_BINARY_PATH=/tmp/yq
export YQ_URL="https://github.com/mikefarah/yq/releases/download/v4.40.3"

#!/bin/env bash

export DT_FILE=/sys/firmware/devicetree/base/model
export INSTALLER_VENV_NAME="ovos-installer"
export LOG_FILE=/var/log/ovos-installer.log
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
declare -a SCENARIO_ALLOWED_OPTIONS=(features channel share_telemetry profile method uninstall rapsberry_pi_tuning hivemind)
export SCENARIO_ALLOWED_OPTIONS
declare -a SCENARIO_ALLOWED_FEATURES=(skills gui)
export SCENARIO_ALLOWED_FEATURES
declare -a SCENARIO_ALLOWED_HIVEMIND_OPTIONS=(host port key password)
export SCENARIO_ALLOWED_HIVEMIND_OPTIONS
export SCENARIO_NAME="scenario.yaml"
export SCENARIO_PATH=""
export USER_ID="$EUID"
export YQ_BINARY_PATH=/tmp/yq
export YQ_URL="https://github.com/mikefarah/yq/releases/download/v4.40.3"

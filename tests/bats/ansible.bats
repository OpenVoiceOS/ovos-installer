#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
}

@test "function_install_ansible" {
    PYTHON="3.9"
    PIP_COMMAND="pip3"
    RUN_AS_HOME=/home/$USER
    VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
    function ansible-galaxy() {
        return 0
    }
    function pip3() {
        return 0
    }
    function ver() {
        printf "%03d%03d%03d" 3 9 0
    }
    export -f ansible-galaxy pip3 ver
    run install_ansible
    assert_success
    unset ansible-galaxy pip3 ver
}

function teardown() {
    rm -f "$LOG_FILE"
}

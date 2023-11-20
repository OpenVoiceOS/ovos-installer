#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
}

@test "function_create_python_venv_exists" {
    RUN_AS_HOME=/home/$USER
    VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
    function source() {
        return 0
    }
    function pip3() {
        return 0
    }
    export -f source pip3
    run mkdir -p "$VENV_PATH"
    run create_python_venv
    assert_success
    unset source pip3
}

@test "function_create_python_venv_not_exists" {
    RUN_AS_HOME=/home/$USER
    VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
    function python3() {
        return 0
    }
    function source() {
        return 0
    }
    function pip3() {
        return 0
    }
    export -f python3 source pip3
    run create_python_venv
    assert_success
    unset python3 source pip3
}

function teardown() {
    rm -f "$LOG_FILE"
}

#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
}

@test "function_create_python_venv_exists" {
    RUN_AS="testuser"
    RUN_AS_HOME=/home/$USER
    VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
    INSTALLER_VENV_NAME="ovos-installer"
    PYTHON="3.9.0"
    ARCH="x86_64"
    RASPBERRYPI_MODEL="N/A"
    USE_UV="false"
    REUSE_CACHED_ARTIFACTS="false"

    function python3() {
        return 0  # Mock python3 command
    }
    function source() {
        return 0  # Mock source command
    }
    function pip3() {
        return 0  # Mock pip3 command
    }
    function chown() {
        return 0  # Mock chown command
    }
    function ver() {
        echo "003009000"  # Mock version comparison
    }
    export -f python3 source pip3 chown ver

    run mkdir -p "$VENV_PATH"
    run create_python_venv
    assert_success

    unset -f python3 source pip3 chown ver
}

@test "function_create_python_venv_not_exists" {
    RUN_AS="testuser"
    RUN_AS_HOME=/home/$USER
    VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
    INSTALLER_VENV_NAME="ovos-installer"
    PYTHON="3.9.0"
    ARCH="x86_64"
    RASPBERRYPI_MODEL="N/A"
    USE_UV="false"
    REUSE_CACHED_ARTIFACTS="false"

    function python3() {
        return 0  # Mock python3 command
    }
    function source() {
        return 0  # Mock source command
    }
    function pip3() {
        return 0  # Mock pip3 command
    }
    function chown() {
        return 0  # Mock chown command
    }
    function ver() {
        echo "003009000"  # Mock version comparison
    }
    export -f python3 source pip3 chown ver

    run create_python_venv
    assert_success

    unset -f python3 source pip3 chown ver
}

# Test install_ansible function (mocked)
@test "function_install_ansible_success" {
    PYTHON="3.9"
    PIP_COMMAND="pip3"
    function ver() {
        printf "%03d%03d%03d" 3 9 0
    }
    export -f ver

    run install_ansible
    assert_success
    unset -f ver
}

function teardown() {
    rm -f "$LOG_FILE"
}

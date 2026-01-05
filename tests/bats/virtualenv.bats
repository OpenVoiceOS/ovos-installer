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
    INSTALLER_VENV_NAME="ovos-installer"
    RUN_AS_HOME="/home/${RUN_AS}"
    VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
    PYTHON="3.9.0"
    ARCH="x86_64"
    RASPBERRYPI_MODEL="N/A"
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
    function uv() {
        return 0  # Mock uv command
    }
    function chown() {
        return 0  # Mock chown command
    }
    function ver() {
        echo "003009000"  # Mock version comparison
    }
    export -f python3 source pip3 uv chown ver

    run mkdir -p "$VENV_PATH"
    run create_python_venv
    assert_success

    unset -f python3 source pip3 uv chown ver
}

@test "function_create_python_venv_not_exists" {
    RUN_AS="testuser"
    INSTALLER_VENV_NAME="ovos-installer"
    RUN_AS_HOME="/home/${RUN_AS}"
    VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
    PYTHON="3.9.0"
    ARCH="x86_64"
    RASPBERRYPI_MODEL="N/A"
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
    function uv() {
        return 0  # Mock uv command
    }
    function chown() {
        return 0  # Mock chown command
    }
    function ver() {
        echo "003009000"  # Mock version comparison
    }
    export -f python3 source pip3 uv chown ver

    run create_python_venv
    assert_success

    unset -f python3 source pip3 uv chown ver
}

# Test install_ansible function (mocked)
@test "function_install_ansible_success" {
    PYTHON="3.9"
    PIP_COMMAND="uv pip"
    function ver() {
        printf "%03d%03d%03d" 3 9 0
    }
    function uv() { return 0; }
    function ansible-galaxy() { return 0; }
    export -f ver uv ansible-galaxy

    run install_ansible
    assert_success
    unset -f ver uv ansible-galaxy
}

function teardown() {
    rm -f "$LOG_FILE"
}

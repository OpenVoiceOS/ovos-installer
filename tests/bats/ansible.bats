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
    PIP_COMMAND="uv pip"
    RUN_AS_HOME=/home/$USER
    VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
    function ansible-galaxy() {
        return 0
    }
    function uv() {
        return 0
    }
    function ver() {
        printf "%03d%03d%03d" 3 9 0
    }
    export -f ansible-galaxy uv ver
    run install_ansible
    assert_success
    unset ansible-galaxy uv ver
}

@test "function_install_ansible_reuses_cached_python_packages_when_enabled" {
    PYTHON="3.11"
    PIP_COMMAND="uv pip"
    RUN_AS_HOME=/home/$USER
    VENV_PATH="${RUN_AS_HOME}/.venvs/${INSTALLER_VENV_NAME}"
    REUSE_CACHED_ARTIFACTS="true"

    function ansible-galaxy() {
        return 0
    }
    function uv() {
        return 1
    }
    function ver() {
        printf "%03d%03d%03d" 3 11 0
    }
    function python_packages_match_versions() {
        return 0
    }

    export -f ansible-galaxy uv ver python_packages_match_versions
    run install_ansible
    assert_success
    unset ansible-galaxy uv ver python_packages_match_versions REUSE_CACHED_ARTIFACTS
}

function teardown() {
    rm -f "$LOG_FILE"
}

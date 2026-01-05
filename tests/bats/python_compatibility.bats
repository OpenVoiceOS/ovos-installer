#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
}

@test "function_check_python_compatibility_allows_supported_version" {
    OVOS_VENV_PYTHON="3.11"
    run check_python_compatibility
    assert_success
}

@test "function_check_python_compatibility_blocks_python_314_version" {
    OVOS_VENV_PYTHON="3.14"
    run check_python_compatibility
    assert_failure
    assert_equal "${status}" "${EXIT_MISSING_DEPENDENCY}"
}

@test "function_check_python_compatibility_blocks_python_314_executable" {
    OVOS_VENV_PYTHON="python3.14"
    run check_python_compatibility
    assert_failure
    assert_equal "${status}" "${EXIT_MISSING_DEPENDENCY}"
}

function teardown() {
    rm -f "$LOG_FILE"
    unset OVOS_VENV_PYTHON PYTHON
}

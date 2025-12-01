#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    RASPBERRYPI_MODEL="N/A"
}

# Test enhanced error handling and exit codes
@test "function_on_error_exit_codes" {
    # Mock the ask_optin function to avoid interactive input
    function ask_optin() {
        return 0  # Simulate user agreeing
    }
    export -f ask_optin

    run on_error
    assert_failure
    assert_equal "${status}" 1

    unset -f ask_optin
}

@test "function_detect_user_permission_denied_exit_code" {
    USER_ID="1000"
    run detect_user
    assert_failure
    assert_equal "${status}" "${EXIT_PERMISSION_DENIED}"
}







# Test input validation
@test "function_required_packages_input_validation_missing_distro" {
    DISTRO_NAME=""
    run required_packages
    assert_failure
    assert_equal "${status}" "${EXIT_MISSING_DEPENDENCY}"
    assert_output --partial "Error: DISTRO_NAME is not set"
}

@test "function_required_packages_input_validation_success" {
    DISTRO_NAME="debian"
    function apt_ensure() {
        return 0
    }
    export -f apt_ensure
    run required_packages
    assert_success
    unset apt_ensure
}

# Test printf usage in error messages
@test "function_on_error_printf_formatting" {
    # Mock the ask_optin function to avoid interactive input
    function ask_optin() {
        return 0  # Simulate user agreeing
    }
    function curl() {
        echo "https://paste.example.com/test-url"
    }
    export -f ask_optin curl

    run on_error
    assert_failure
    assert_output --partial "Unable to finalize the process"
    assert_output --partial "Please share this URL with us"

    unset -f ask_optin curl
}

# Test constants are properly loaded
@test "constants_exit_codes_loaded" {
    assert_equal "${EXIT_SUCCESS}" "0"
    assert_equal "${EXIT_FAILURE}" "1"
    assert_equal "${EXIT_PERMISSION_DENIED}" "2"
    assert_equal "${EXIT_OS_NOT_SUPPORTED}" "3"
    assert_equal "${EXIT_INVALID_ARGUMENT}" "4"
    assert_equal "${EXIT_MISSING_DEPENDENCY}" "5"
}

function teardown() {
    rm -f "$LOG_FILE"
    unset RUN_AS RUN_AS_UID SUDO_USER SUDO_UID USER_ID
}

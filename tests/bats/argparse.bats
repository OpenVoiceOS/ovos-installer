#!/usr/bin/env bats
# Tests for argparse.sh functions
# Following BATS best practices for comprehensive test coverage

setup() {
    # Load BATS testing framework
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    # Load source files under test
    load ../../utils/constants.sh
    load ../../utils/argparse.sh

    # Set up test environment
    export LOG_FILE="/tmp/ovos-installer-test.log"

    # Clean up any existing test artifacts
    rm -f "$LOG_FILE"
}

teardown() {
    # Clean up test artifacts
    rm -f "$LOG_FILE"

    # Reset global variables that may have been modified
    unset DEBUG CONFIRM_UNINSTALL_CLI USE_UV REUSE_CACHED_ARTIFACTS
}

# Test usage function
@test "function_usage_output" {
    run usage
    assert_success
    assert_output --partial "Usage: "
    assert_output --partial "Options:"
    assert_output --partial "-h, --help"
    assert_output --partial "-d, --debug"
    assert_output --partial "-u, --uninstall"
}

@test "function_usage_exit_code" {
    run usage
    assert_success
    assert_equal "${status}" 0
}

# Test handle_options function
@test "function_handle_options_debug_short" {
    handle_options -d
    assert_equal "${DEBUG}" "true"
}

@test "function_handle_options_debug_long" {
    handle_options --debug
    assert_equal "${DEBUG}" "true"
}

@test "function_handle_options_uninstall_short" {
    handle_options -u
    assert_equal "${CONFIRM_UNINSTALL_CLI}" "true"
}

@test "function_handle_options_uninstall_long" {
    handle_options --uninstall
    assert_equal "${CONFIRM_UNINSTALL_CLI}" "true"
}

@test "function_handle_options_help_short" {
    run handle_options -h
    assert_success
    assert_equal "${status}" 0
}

@test "function_handle_options_help_long" {
    run handle_options --help
    assert_success
    assert_equal "${status}" 0
}

@test "function_handle_options_multiple_args" {
    handle_options -d -u
    assert_equal "${DEBUG}" "true"
    assert_equal "${CONFIRM_UNINSTALL_CLI}" "true"
}

@test "function_handle_options_invalid_option" {
    run handle_options --invalid
    assert_failure
    assert_equal "${status}" 1
    assert_output --partial "Invalid option: --invalid"
}

@test "function_handle_options_environment_variables" {
    USE_UV="false"
    REUSE_CACHED_ARTIFACTS="true"
    export USE_UV REUSE_CACHED_ARTIFACTS

    handle_options
    assert_equal "${USE_UV}" "true"
    assert_equal "${REUSE_CACHED_ARTIFACTS}" "true"

    unset USE_UV REUSE_CACHED_ARTIFACTS
}

@test "function_handle_options_environment_defaults" {
    # Test default values when env vars not set
    handle_options
    assert_equal "${USE_UV}" "true"
    assert_equal "${REUSE_CACHED_ARTIFACTS}" "false"
}

@test "function_handle_options_mixed_args_and_env" {
    USE_UV="false"
    export USE_UV

    handle_options -d
    assert_equal "${DEBUG}" "true"
    assert_equal "${USE_UV}" "true"

    unset USE_UV
}

# Test argument parsing edge cases
@test "function_handle_options_empty_args" {
    run handle_options
    assert_success
}

@test "function_handle_options_no_args" {
    run handle_options
    assert_success
}

function teardown() {
    unset DEBUG CONFIRM_UNINSTALL_CLI USE_UV REUSE_CACHED_ARTIFACTS
}

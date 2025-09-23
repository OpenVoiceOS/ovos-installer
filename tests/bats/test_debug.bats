#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
}

@test "debug_in_array_not_found" {
    local test_array=("apple" "banana" "cherry")

    # Mock the ask_optin function to avoid interactive input
    function ask_optin() {
        printf '%s\n' "Error: unsupported option"
        exit 1
    }
    export -f ask_optin

    run in_array test_array "grape"
    assert_failure
    assert_output --partial "Error: unsupported option"

    unset -f ask_optin
}

function teardown() {
    rm -f "$LOG_FILE"
}

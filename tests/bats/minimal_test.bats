#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
}

@test "minimal_in_array_test" {
    local test_array=("apple" "banana" "cherry")

    # Mock the ask_optin function to avoid interactive input
    function ask_optin() {
        echo "Error: unsupported option"
        exit 1
    }
    export -f ask_optin

    run in_array test_array "grape"
    assert_failure
    assert_output --partial "Error: unsupported option"

    unset -f ask_optin
}

#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
}

@test "function_on_error_detected" {
    run on_error
    assert_failure
    assert_output --partial "Please check $LOG_FILE for more details"
}

@test "function_delete_log_if_exist" {
    run touch "$LOG_FILE"
    run delete_log
    assert_success
}

@test "function_delete_log_non_exist" {
    run delete_log
    assert_success
}

@test "function_detect_user_root" {
    USER_ID="0"
    run detect_user
    assert_success
}

@test "function_detect_user_non_root" {
    run detect_user
    assert_failure
    assert_output --partial "This script must be run as root or with sudo"
}

@test "function_detect_cpu_instructions_capable" {
    function grep() {
        return 0
    }
    export -f grep
    detect_cpu_instructions
    assert_equal "$CPU_IS_CAPABLE" "true"
    unset grep
}

@test "function_detect_cpu_instructions_not_capable" {
    function grep() {
        return 1
    }
    export -f grep
    detect_cpu_instructions
    assert_equal "$CPU_IS_CAPABLE" "false"
    unset grep
}

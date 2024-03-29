#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
}

@test "function_install_i2c_get_exists" {
    function i2cdetect() {
        echo "2f"
    }
    export -f i2cdetect
    run i2c_get "2f"
    assert_success
    unset i2cdetect
}

@test "function_install_i2c_get_non_exists" {
    function i2cdetect() {
        echo ""
    }
    export -f i2cdetect
    run i2c_get "2f"
    assert_failure
    unset i2cdetect
}

function teardown() {
    rm -f "$LOG_FILE"
}

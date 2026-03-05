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

@test "function_install_i2c_get_falls_back_to_other_buses" {
    OVOS_I2C_SCAN_BUSES="1 10"
    export OVOS_I2C_SCAN_BUSES

    function i2cdetect() {
        if [[ "$3" == "10" ]]; then
            echo "2f"
        else
            echo ""
        fi
    }
    export -f i2cdetect

    run i2c_get "2f"
    assert_success

    unset i2cdetect
    unset OVOS_I2C_SCAN_BUSES
}

function teardown() {
    rm -f "$LOG_FILE"
}

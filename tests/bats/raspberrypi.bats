#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    DT_FILE=/tmp/model
}

@test "function_is_raspeberrypi_soc_detected" {
    function iw() {
        exit 0
    }
    export -f iw
    echo "Raspberry Pi 4 Model B Rev 1.5" >"$DT_FILE"
    is_raspeberrypi_soc
    assert_equal "$RASPBERRYPI_MODEL" "Raspberry Pi 4 Model B Rev 1.5"
    unset -f iw
}

@test "function_is_raspeberrypi_soc_file_exists_but_not_rpi" {
    function iw() {
        exit 0
    }
    export -f iw    
    echo "Fake Board Name 0.0" >"$DT_FILE"
    is_raspeberrypi_soc
    assert_equal "$RASPBERRYPI_MODEL" "N/A"
    unset -f iw
}

@test "function_is_raspeberrypi_soc_not_detected" {
    function iw() {
        exit 0
    }
    export -f iw    
    DT_FILE=/sys/fake/model
    is_raspeberrypi_soc
    assert_equal "$RASPBERRYPI_MODEL" "N/A"
    unset -f iw
}

function teardown() {
    rm -f "$DT_FILE" "$LOG_FILE"
}

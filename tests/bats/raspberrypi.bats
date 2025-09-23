#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    DT_FILE=/tmp/model
    RASPBERRYPI_MODEL=""
}

@test "function_is_raspeberrypi_soc_detected" {
    function iw() {
        exit 0
    }
    run echo "Raspberry Pi 4 Model B Rev 1.5" >"$DT_FILE"
    run is_raspeberrypi_soc
    run assert_equal "$RASPBERRYPI_MODEL" "Raspberry Pi 4 Model B Rev 1.5"
}

@test "function_is_raspeberrypi_soc_file_exists_but_not_rpi" {
    function iw() {
        exit 0
    }
    run echo "Fake Board Name 0.0" >"$DT_FILE"
    run is_raspeberrypi_soc
    run assert_equal "$RASPBERRYPI_MODEL" "N/A"
}

@test "function_is_raspeberrypi_soc_not_detected" {
    function iw() {
        exit 0
    }
    DT_FILE=/sys/fake/model
    run is_raspeberrypi_soc
    run assert_equal "$RASPBERRYPI_MODEL" "N/A"
}

function teardown() {
    rm -f "$DT_FILE" "$LOG_FILE"
}

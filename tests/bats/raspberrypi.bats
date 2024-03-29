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
    echo "Raspberry Pi 4 Model B Rev 1.5" >"$DT_FILE"
    is_raspeberrypi_soc
    assert_equal "$RASPBERRYPI_MODEL" "Raspberry Pi 4 Model B Rev 1.5"
}

@test "function_is_raspeberrypi_soc_file_exists_but_not_rpi" {
    echo "Fake Board Name 0.0" >"$DT_FILE"
    is_raspeberrypi_soc
    assert_equal "$RASPBERRYPI_MODEL" "N/A"
}

@test "function_is_raspeberrypi_soc_not_detected" {
    DT_FILE=/sys/fake/model
    is_raspeberrypi_soc
    assert_equal "$RASPBERRYPI_MODEL" "N/A"
}

function teardown() {
    rm -f "$DT_FILE" "$LOG_FILE"
}

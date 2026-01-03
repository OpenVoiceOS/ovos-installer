#!/usr/bin/env bats

function setup() {
    load "../test_helper/bats-support/load"
    load "../test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    RUN_AS="testuser"
    RASPBERRYPI_MODEL="N/A"
}

@test "function_detect_display_x11" {
    function python3() {
        if [[ "$1" == *"detect_display.py"* ]]; then
             echo "x11"
        fi
    }
    export -f python3

    # Needs script presence
    touch "utils/detect_display.py"

    DISPLAY_SERVER=""
    detect_display
    assert_equal "$DISPLAY_SERVER" "x11"

    rm -f "utils/detect_display.py"
    unset python3
}

@test "function_detect_display_wayland" {
    function python3() {
        if [[ "$1" == *"detect_display.py"* ]]; then
             echo "wayland"
        fi
    }
    export -f python3
    touch "utils/detect_display.py"

    DISPLAY_SERVER=""
    detect_display
    assert_equal "$DISPLAY_SERVER" "wayland"

    rm -f "utils/detect_display.py"
    unset python3
}

@test "function_detect_display_no_display" {
    function python3() {
        echo "N/A"
    }
    export -f python3
    touch "utils/detect_display.py"

    DISPLAY_SERVER=""
    detect_display
    assert_equal "$DISPLAY_SERVER" "N/A"

    rm -f "utils/detect_display.py"
    unset python3
}

function teardown() {
    rm -f "$LOG_FILE"
}

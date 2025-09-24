#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    RUN_AS="testuser"
    RASPBERRYPI_MODEL="N/A"
}

@test "function_detect_display_x11" {
    function loginctl() {
        if [[ "$*" == *"show-session"* ]]; then
            echo "x11"
        else
            echo "3 testuser seat0 x11"
        fi
    }
    export -f loginctl
    DISPLAY_SERVER=""
    detect_display
    assert_equal "$DISPLAY_SERVER" "x11"
    unset loginctl
}

@test "function_detect_display_wayland" {
    function loginctl() {
        if [[ "$*" == *"show-session"* ]]; then
            echo "wayland"
        else
            echo "6 testuser seat0 wayland"
        fi
    }
    export -f loginctl
    DISPLAY_SERVER=""
    detect_display
    assert_equal "$DISPLAY_SERVER" "wayland"
    unset loginctl
}

@test "function_detect_display_no_display" {
    function loginctl() {
        if [[ "$*" == *"show-session"* ]]; then
            echo "tty"
        else
            echo "11 testuser seat0 tty"
        fi
    }
    export -f loginctl
    DISPLAY_SERVER=""
    detect_display
    assert_equal "$DISPLAY_SERVER" "N/A"
    unset loginctl
}

function teardown() {
    rm -f "$LOG_FILE"
}

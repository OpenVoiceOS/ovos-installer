#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
}

@test "function_detect_display_x11" {
    function loginctl() {
        echo "x11"
    }
    sessions="3"
    export -f loginctl
    detect_display
    assert_equal "$DISPLAY_SERVER" "x11"
    unset loginctl
}

@test "function_detect_display_wayland" {
    function loginctl() {
        echo "wayland"
    }
    sessions="6"
    export -f loginctl
    detect_display
    assert_equal "$DISPLAY_SERVER" "wayland"
    unset loginctl
}

@test "function_detect_display_no_display" {
    function loginctl() {
        echo "tty"
    }
    sessions="11"
    export -f loginctl
    detect_display
    assert_equal "$DISPLAY_SERVER" "N/A"
    unset loginctl
}

function teardown() {
    rm -f "$LOG_FILE"
}

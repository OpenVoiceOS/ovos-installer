#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
}

@test "function_download_yq_file_removal" {
    run touch /tmp/yq
    function uname() {
        if [ "$1" == "-m" ]; then
            echo "x86_64"
        elif [ "$1" == "-s" ]; then
            echo "Linux"
        fi
    }
    function curl() {
        exit 0
    }
    export -f uname curl
    run download_yq
    assert_success
    unset uname curl
}

@test "function_download_yq_download_linux_amd64" {
    function uname() {
        if [ "$1" == "-m" ]; then
            echo "x86_64"
        elif [ "$1" == "-s" ]; then
            echo "Linux"
        fi
    }
    function curl() {
        exit 0
    }
    export -f uname curl
    run download_yq
    assert_success
    unset uname curl
}

@test "function_download_yq_download_linux_arm64" {
    function uname() {
        if [ "$1" == "-m" ]; then
            echo "aarch64"
        elif [ "$1" == "-s" ]; then
            echo "Linux"
        fi
    }
    function curl() {
        exit 0
    }
    export -f uname curl
    run download_yq
    assert_success
    unset uname curl
}

@test "function_download_yq_download_linux_arm65" {
    function uname() {
        if [ "$1" == "-m" ]; then
            echo "arm65"
        elif [ "$1" == "-s" ]; then
            echo "Linux"
        fi
    }
    function curl() {
        exit 1
    }
    export -f uname curl
    run download_yq
    assert_failure
    unset uname curl
}

@test "function_detect_scenario_directory_found" {
    SCENARIO_PATH=/tmp/ovos-installer
    detect_scenario
    assert_equal "$SCENARIO_FOUND" "false"
}

@test "function_detect_scenario_directory_not_found" {
    detect_scenario
    assert_equal "$SCENARIO_FOUND" "false"
}

function teardown() {
    rm -f "$LOG_FILE" /tmp/yq
    rm -rf "$SCENARIO_PATH"
}

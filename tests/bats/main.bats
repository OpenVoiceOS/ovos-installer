#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
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
    USER_ID=0
    run detect_user
    assert_success
}

@test "function_detect_user_non_root" {
    run detect_user
    assert_output --partial "This script must be run as root or with sudo"
}

@test "function_detect_cpu_instructions_capable" {
    function grep() {
        return 0
    }
    export -f grep
    detect_cpu_instructions
    echo "$CPU_IS_CAPABLE"
    [ "$CPU_IS_CAPABLE" == "true" ]
    unset grep
}

@test "function_detect_cpu_instructions_not_capable" {
    function grep() {
        return 1
    }
    export -f grep
    detect_cpu_instructions
    echo "$CPU_IS_CAPABLE"
    [ "$CPU_IS_CAPABLE" == "false" ]
    unset grep
}

@test "function_detect_existing_instance_docker_exists" {
    function docker() {
        echo "adf1dedc2025"
    }
    export -f docker
    detect_existing_instance
    echo "$EXISTING_INSTANCE"
    [ "$EXISTING_INSTANCE" == "true" ]
    unset docker
}

@test "function_detect_existing_instance_docker_non_exists" {
    function docker() {
        return 0
    }
    export -f docker
    detect_existing_instance
    echo "$EXISTING_INSTANCE"
    [ "$EXISTING_INSTANCE" == "false" ]
    unset docker
}

@test "function_detect_existing_instance_podman_exists" {
    function docker() {
        return 0
    }
    function podman() {
        echo "adf1dedc2025"
    }
    export -f docker podman
    detect_existing_instance
    echo "$EXISTING_INSTANCE"
    [ "$EXISTING_INSTANCE" == "true" ]
    unset docker podman
}

@test "function_detect_existing_instance_podman_non_exists" {
    function docker() {
        return 0
    }
    function podman() {
        return 0
    }
    export -f docker podman
    detect_existing_instance
    echo "$EXISTING_INSTANCE"
    [ "$EXISTING_INSTANCE" == "false" ]
    unset docker podman
}

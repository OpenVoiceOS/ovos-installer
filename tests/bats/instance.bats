#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
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

@test "function_detect_existing_instance_venv_exists" {
    RUN_AS_HOME=$USER
    run mkdir -p "$RUN_AS_HOME/.venvs/ovos"
    function docker() {
        return 0
    }
    function podman() {
        return 0
    }
    export -f docker podman
    detect_existing_instance
    echo "$EXISTING_INSTANCE"
    [ "$EXISTING_INSTANCE" == "true" ]
    unset docker podman 
}

@test "function_detect_existing_instance_venv_non_exists" {
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
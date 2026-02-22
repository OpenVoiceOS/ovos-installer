#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    RUN_AS_HOME="/home/testuser"
}

@test "function_detect_existing_instance_docker_exists" {
    function uname() {
        if [[ "$1" == "-s" ]]; then
            echo "Linux"
            return 0
        fi
        command uname "$@"
    }
    function docker() {
        # Match the name-based detection in utils/common.sh
        if [[ "$1" == "ps" ]]; then
            echo "ovos_core"
        fi
    }
    export -f uname docker
    detect_existing_instance
    assert_equal "$EXISTING_INSTANCE" "true"
    unset uname docker
}

@test "function_detect_existing_instance_docker_non_exists" {
    function uname() {
        if [[ "$1" == "-s" ]]; then
            echo "Linux"
            return 0
        fi
        command uname "$@"
    }
    function docker() {
        return 0
    }
    export -f uname docker
    detect_existing_instance
    assert_equal "$EXISTING_INSTANCE" "false"
    unset uname docker
}

@test "function_detect_existing_instance_podman_exists" {
    function uname() {
        if [[ "$1" == "-s" ]]; then
            echo "Linux"
            return 0
        fi
        command uname "$@"
    }
    function docker() {
        return 0
    }
    function podman() {
        if [[ "$1" == "ps" ]]; then
            echo "ovos_messagebus"
        fi
    }
    export -f uname docker podman
    detect_existing_instance
    assert_equal "$EXISTING_INSTANCE" "true"
    unset uname docker podman
}

@test "function_detect_existing_instance_podman_non_exists" {
    function uname() {
        if [[ "$1" == "-s" ]]; then
            echo "Linux"
            return 0
        fi
        command uname "$@"
    }
    function docker() {
        return 0
    }
    function podman() {
        return 0
    }
    export -f uname docker podman
    detect_existing_instance
    assert_equal "$EXISTING_INSTANCE" "false"
    unset uname docker podman
}

@test "function_detect_existing_instance_venv_exists" {
    RUN_AS_HOME="$BATS_TMPDIR/testuser"
    run mkdir -p "$RUN_AS_HOME/.venvs/ovos/bin"
    run touch "$RUN_AS_HOME/.venvs/ovos/pyvenv.cfg"
    run touch "$RUN_AS_HOME/.venvs/ovos/bin/ovos-core"
    run chmod +x "$RUN_AS_HOME/.venvs/ovos/bin/ovos-core"
    function docker() {
        return 0
    }
    function podman() {
        return 0
    }
    export -f docker podman
    detect_existing_instance
    assert_equal "$EXISTING_INSTANCE" "true"
    unset docker podman
}

@test "function_detect_existing_instance_venv_non_exists" {
    RUN_AS_HOME="$BATS_TMPDIR/testuser2"
    function docker() {
        return 0
    }
    function podman() {
        return 0
    }
    export -f docker podman
    detect_existing_instance
    assert_equal "$EXISTING_INSTANCE" "false"
    unset docker podman
}

@test "function_detect_existing_instance_skips_container_runtime_checks_on_macos" {
    docker_called="false"
    podman_called="false"

    function uname() {
        if [[ "$1" == "-s" ]]; then
            echo "Darwin"
            return 0
        fi
        command uname "$@"
    }
    function docker() {
        docker_called="true"
        echo "docker should not be called on macOS" >&2
        return 99
    }
    function podman() {
        podman_called="true"
        echo "podman should not be called on macOS" >&2
        return 99
    }

    export -f uname docker podman
    detect_existing_instance
    assert_equal "$EXISTING_INSTANCE" "false"
    assert_equal "${INSTANCE_TYPE:-}" ""
    assert_equal "$docker_called" "false"
    assert_equal "$podman_called" "false"
    unset uname docker podman
}

function teardown() {
    rm -f "$LOG_FILE"
}

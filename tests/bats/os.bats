#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    OS_RELEASE=/tmp/os-release
    WSL_FILE=/tmp/wsl.conf
    cat <<EOF >"$OS_RELEASE"
VERSION="39 (Workstation Edition)"
VERSION_ID="39"
ID=fedora
EOF
    cat <<EOF >"$WSL_FILE"
[boot]
systemd=true
EOF
}

@test "function_get_os_information_kernel_version" {
    function uname() {
        echo "6.1.61-v8+"
    }
    export -f uname
    get_os_information
    assert_equal "$KERNEL" "6.1.61-v8+"
    unset uname
}

@test "function_get_os_information_python_version" {
    function python3() {
        echo "3.11.2"
    }
    export -f python3
    get_os_information
    assert_equal "$PYTHON" "3.11.2"
    unset python3
}

@test "function_get_os_information_os_name" {
    get_os_information
    assert_equal "$DISTRO_NAME" "fedora"
}

@test "function_get_os_information_os_version" {
    get_os_information
    assert_equal "$DISTRO_VERSION" "39 (Workstation Edition)"
}

@test "function_get_os_information_no_os_release" {
    OS_RELEASE=/tmp/no-os-release
    function uname() {
        echo "Darwin MacBook-Pro.local 20.1.0 Darwin Kernel"
    }
    export -f uname
    run get_os_information
    assert_output --partial "Darwin MacBook-Pro.local 20.1.0 Darwin Kernel"
    unset uname
}

@test "function_wsl2_requirements_valid" {
    WSL_FILE=/tmp/wsl.conf
    KERNEL="5.15.133.1-microsoft-standard-WSL2"
    run wsl2_requirements
    assert_success
}

@test "function_wsl2_requirements_no_valid" {
    truncate -s 0 "$WSL_FILE"
    KERNEL="5.15.133.1-microsoft-standard-WSL2"
    run wsl2_requirements
    assert_failure
}

function teardown() {
    rm -f "$OS_RELEASE" "$LOG_FILE" "$WSL_FILE"
}

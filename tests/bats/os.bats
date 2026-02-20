#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE="$BATS_TMPDIR/ovos-installer.log"
    OS_RELEASE="$BATS_TMPDIR/os-release"
    WSL_FILE="$BATS_TMPDIR/wsl.conf"
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
        case "$1" in
        -m) echo "aarch64" ;;
        -r) echo "6.1.61-v8+" ;;
        -s) echo "Linux" ;;
        *) echo "Linux" ;;
        esac
    }
    export -f uname
    get_os_information
    assert_equal "$KERNEL" "6.1.61-v8+"
    unset -f uname
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
    assert_equal "$DISTRO_LABEL" "Fedora 39 (Workstation Edition)"
}

@test "function_get_os_information_no_os_release" {
    OS_RELEASE="$BATS_TMPDIR/no-os-release"
    function uname() {
        case "$1" in
        -m) echo "x86_64" ;;
        -r) echo "6.8.12" ;;
        -s) echo "Linux" ;;
        *) echo "Linux" ;;
        esac
    }
    export -f uname
    get_os_information
    assert_equal "$DISTRO_NAME" "Linux"
    assert_equal "$DISTRO_VERSION" ""
    assert_equal "$DISTRO_VERSION_ID" ""
    assert_equal "$DISTRO_LABEL" "Linux"
    unset -f uname
}

@test "function_get_os_information_macos" {
    OS_RELEASE="$BATS_TMPDIR/no-os-release"
    function uname() {
        case "$1" in
        -m) echo "arm64" ;;
        -r) echo "23.5.0" ;;
        -s) echo "Darwin" ;;
        *) echo "Darwin" ;;
        esac
    }
    function sw_vers() {
        if [ "$1" == "-productVersion" ]; then
            echo "14.5"
        fi
    }
    export -f uname sw_vers
    get_os_information
    assert_equal "$DISTRO_NAME" "macos"
    assert_equal "$DISTRO_VERSION_ID" "14.5"
    assert_equal "$DISTRO_VERSION" "macOS 14.5"
    assert_equal "$DISTRO_LABEL" "macOS 14.5"
    assert_equal "$ARCH" "arm64"
    assert_equal "$KERNEL" "23.5.0"
    unset -f uname sw_vers
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

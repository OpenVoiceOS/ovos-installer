#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    OS_RELEASE=/tmp/os-release
    cat <<EOF >"$OS_RELEASE"
VERSION="39 (Workstation Edition)"
ID=fedora
EOF
}

# Test the new distro-specific package installation functions
@test "function_install_debian_packages_success" {
    function apt_ensure() {
        return 0
    }
    export -f apt_ensure
    run install_debian_packages "python3" "curl"
    assert_success
    unset apt_ensure
}

@test "function_install_debian_packages_failure" {
    function apt_ensure() {
        return 1
    }
    export -f apt_ensure
    run install_debian_packages "python3" "curl"
    assert_failure
    unset apt_ensure
}

@test "function_install_fedora_packages_success" {
    function dnf() {
        return 0
    }
    export -f dnf
    run install_fedora_packages "python3" "curl"
    assert_success
    unset dnf
}

@test "function_install_fedora_packages_failure" {
    function dnf() {
        return 1
    }
    export -f dnf
    run install_fedora_packages "python3" "curl"
    assert_failure
    unset dnf
}

@test "function_install_rhel_packages_success" {
    function dnf() {
        return 0
    }
    export -f dnf
    run install_rhel_packages "python3" "curl"
    assert_success
    unset dnf
}

@test "function_install_opensuse_packages_success" {
    function zypper() {
        return 0
    }
    export -f zypper
    run install_opensuse_packages "python3" "curl"
    assert_success
    unset zypper
}

@test "function_install_arch_packages_success" {
    function pacman() {
        return 0
    }
    export -f pacman
    run install_arch_packages "python" "curl"
    assert_success
    unset pacman
}



function teardown() {
    rm -f "$OS_RELEASE" "$LOG_FILE"
}

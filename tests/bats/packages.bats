#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    OS_RELEASE=/tmp/os-release
    # Stub package managers to avoid real system calls
    function apt_ensure() { return 0; }
    function dnf() { return 0; }
    function pacman() { return 0; }
    function zypper() { return 0; }
    export -f apt_ensure dnf pacman zypper
    RASPBERRYPI_MODEL="N/A"
    cat <<EOF >"$OS_RELEASE"
VERSION="39 (Workstation Edition)"
ID=fedora
EOF
}

@test "function_required_packages_debian" {
    DISTRO_NAME="debian"
    run required_packages
    assert_success
}

@test "function_required_packages_popos" {
    DISTRO_NAME="pop"
    run required_packages
    assert_success
}

@test "function_required_packages_raspbian" {
    DISTRO_NAME="raspbian"
    run required_packages
    assert_success
}

@test "function_required_packages_ubuntu" {
    DISTRO_NAME="ubuntu"
    run required_packages
    assert_success
}

@test "function_required_packages_fedora" {
    DISTRO_NAME="fedora"
    run required_packages
    assert_success
}

@test "function_required_packages_centos" {
    DISTRO_NAME="centos"
    run required_packages
    assert_success
}

@test "function_required_packages_rocky" {
    DISTRO_NAME="rocky"
    run required_packages
    assert_success
}

@test "function_required_packages_almalinux" {
    DISTRO_NAME="almalinux"
    run required_packages
    assert_success
}

@test "function_required_packages_manjaro" {
    DISTRO_NAME="manjaro"
    run required_packages
    assert_success
}

@test "function_required_packages_arch" {
    DISTRO_NAME="arch"
    run required_packages
    assert_success
}

@test "function_required_packages_opensuse_leap" {
    DISTRO_NAME="opensuse-leap"
    run required_packages
    assert_success
}

@test "function_required_packages_opensuse_tumbleweed" {
    DISTRO_NAME="opensuse-tumbleweed"
    run required_packages
    assert_success
}

@test "function_required_packages_opensuse_slowroll" {
    DISTRO_NAME="opensuse-slowroll"
    run required_packages
    assert_success
}

@test "function_required_packages_linuxmint" {
    DISTRO_NAME="linuxmint"
    run required_packages
    assert_success
}

@test "function_required_packages_zorinos" {
    DISTRO_NAME="zorin"
    run required_packages
    assert_success
}

@test "function_required_packages_debian_fail" {
    DISTRO_NAME="debian"
    function apt_ensure() {
        return 1
    }
    export -f apt_ensure
    run required_packages
    assert_failure
}

@test "function_required_packages_popos_fail" {
    DISTRO_NAME="pop"
    function apt_ensure() {
        return 1
    }
    export -f apt_ensure
    run required_packages
    assert_failure
}

@test "function_required_packages_raspbian_fail" {
    DISTRO_NAME="raspbian"
    function apt_ensure() {
        return 1
    }
    export -f apt_ensure
    run required_packages
    assert_failure
}

@test "function_required_packages_ubuntu_fail" {
    DISTRO_NAME="ubuntu"
    function apt_ensure() {
        return 1
    }
    export -f apt_ensure
    run required_packages
    assert_failure
}

@test "function_required_packages_fedora_fail" {
    DISTRO_NAME="fedora"
    function dnf() {
        return 1
    }
    export -f dnf
    run required_packages
    assert_failure
}

@test "function_required_packages_centos_fail" {
    DISTRO_NAME="centos"
    function dnf() {
        return 1
    }
    export -f dnf
    run required_packages
    assert_failure
}

@test "function_required_packages_rocky_fail" {
    DISTRO_NAME="rocky"
    function dnf() {
        return 1
    }
    export -f dnf
    run required_packages
    assert_failure
}

@test "function_required_packages_almalinux_fail" {
    DISTRO_NAME="almalinux"
    function dnf() {
        return 1
    }
    export -f dnf
    run required_packages
    assert_failure
}

@test "function_required_packages_manjaro_fail" {
    DISTRO_NAME="manjaro"
    function pacman() {
        return 1
    }
    export -f pacman
    run required_packages
    assert_failure
}

@test "function_required_packages_arch_fail" {
    DISTRO_NAME="arch"
    function pacman() {
        return 1
    }
    export -f pacman
    run required_packages
    assert_failure
}

@test "function_required_packages_opensuse_leap_fail" {
    DISTRO_NAME="opensuse-leap"
    function zypper() {
        return 1
    }
    export -f zypper
    run required_packages
    assert_failure
}

@test "function_required_packages_opensuse_tumbleweed_fail" {
    DISTRO_NAME="opensuse-tumbleweed"
    function zypper() {
        return 1
    }
    export -f zypper
    run required_packages
    assert_failure
}

@test "function_required_packages_opensuse_slowroll_fail" {
    DISTRO_NAME="opensuse-slowroll"
    function zypper() {
        return 1
    }
    export -f zypper
    run required_packages
    assert_failure
}

@test "function_required_packages_linuxmint_fail" {
    DISTRO_NAME="linuxmint"
    function apt_ensure() {
        return 1
    }
    export -f apt_ensure
    run required_packages
    assert_failure
}

@test "function_required_packages_zorinos_fail" {
    DISTRO_NAME="zorin"
    function apt_ensure() {
        return 1
    }
    export -f apt_ensure
    run required_packages
    assert_failure
}

@test "function_required_packages_unknown" {
    DISTRO_NAME="unknown"
    run required_packages
    assert_output --partial "Operating system not supported."
}

function teardown() {
    rm -f "$OS_RELEASE" "$LOG_FILE"
}

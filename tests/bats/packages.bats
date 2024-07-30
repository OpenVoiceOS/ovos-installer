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

@test "function_required_packages_debian" {
    DISTRO_NAME="debian"
    function apt-get() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_raspbian" {
    DISTRO_NAME="raspbian"
    function apt-get() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_ubuntu" {
    DISTRO_NAME="ubuntu"
    function apt-get() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_fedora" {
    DISTRO_NAME="fedora"
    function dnf() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_centos" {
    DISTRO_NAME="centos"
    function dnf() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_rocky" {
    DISTRO_NAME="rocky"
    function dnf() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_almalinux" {
    DISTRO_NAME="almalinux"
    function dnf() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_manjaro" {
    DISTRO_NAME="manjaro"
    function pacman() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_arch" {
    DISTRO_NAME="arch"
    function pacman() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_opensuse_leap" {
    DISTRO_NAME="opensuse-leap"
    function zypper() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_opensuse_tumbleweed" {
    DISTRO_NAME="opensuse-tumbleweed"
    function zypper() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_opensuse_slowroll" {
    DISTRO_NAME="opensuse-slowroll"
    function zypper() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_linuxmint" {
    DISTRO_NAME="linuxmint"
    function apt-get() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_zorinos" {
    DISTRO_NAME="zorin"
    function apt-get() {
        exit 0
    }
    run required_packages
    assert_success
}

@test "function_required_packages_debian_fail" {
    DISTRO_NAME="debian"
    function apt-get() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_raspbian_fail" {
    DISTRO_NAME="raspbian"
    function apt-get() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_ubuntu_fail" {
    DISTRO_NAME="ubuntu"
    function apt-get() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_fedora_fail" {
    DISTRO_NAME="fedora"
    function dnf() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_centos_fail" {
    DISTRO_NAME="centos"
    function dnf() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_rocky_fail" {
    DISTRO_NAME="rocky"
    function dnf() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_almalinux_fail" {
    DISTRO_NAME="almalinux"
    function dnf() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_manjaro_fail" {
    DISTRO_NAME="manjaro"
    function pacman() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_arch_fail" {
    DISTRO_NAME="arch"
    function pacman() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_opensuse_leap_fail" {
    DISTRO_NAME="opensuse-leap"
    function zypper() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_opensuse_tumbleweed_fail" {
    DISTRO_NAME="opensuse-leap"
    function zypper() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_opensuse_slowroll_fail" {
    DISTRO_NAME="opensuse-slowroll"
    function zypper() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_linuxmint_fail" {
    DISTRO_NAME="linuxmint"
    function apt-get() {
        exit 1
    }
    run required_packages
    assert_failure
}

@test "function_required_packages_zorinos_fail" {
    DISTRO_NAME="zorin"
    function apt-get() {
        exit 1
    }
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

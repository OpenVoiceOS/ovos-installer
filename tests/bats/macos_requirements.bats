#!/usr/bin/env bats
#
# macos_requirements: Homebrew builds nothing for Intel Macs any more and little for
# macOS 14, and an install there stopped halfway, at the first formula without a
# package. A new install stops before it starts instead; an existing one must still
# be able to uninstall.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE="$(mktemp)"
    export DISTRO_NAME="macos" EXISTING_INSTANCE="false"
    unset OVOS_INSTALLER_ALLOW_UNSUPPORTED_MACOS
    function sysctl() { echo "${FAKE_TRANSLATED:-0}"; }
}

function teardown() {
    rm -f "$LOG_FILE"
    unset -f sysctl
}

@test "macos requirements: Apple Silicon on macOS 15 or later goes ahead" {
    local version
    for version in 15.0 15.7.1 26.1; do
        ARCH="arm64" DISTRO_VERSION_ID="$version" run macos_requirements
        assert_success
        refute_output --partial "needs macOS 15"
    done
}

@test "macos requirements: an Intel Mac stops before anything is changed" {
    ARCH="x86_64" DISTRO_VERSION_ID="15.7" run macos_requirements
    assert_equal "$status" "$EXIT_OS_NOT_SUPPORTED"
    assert_output --partial "stopped building packages for Intel Macs"
    assert_output --partial "OVOS_INSTALLER_ALLOW_UNSUPPORTED_MACOS=true"
}

@test "macos requirements: macOS 14 on Apple Silicon stops too" {
    ARCH="arm64" DISTRO_VERSION_ID="14.6.1" run macos_requirements
    assert_equal "$status" "$EXIT_OS_NOT_SUPPORTED"
    assert_output --partial "macOS 14.6.1"
}

@test "macos requirements: a terminal under Rosetta is told to run natively" {
    FAKE_TRANSLATED=1 ARCH="x86_64" DISTRO_VERSION_ID="26.1" run macos_requirements
    assert_equal "$status" "$EXIT_OS_NOT_SUPPORTED"
    assert_output --partial "runs under Rosetta"
}

@test "macos requirements: an existing install is warned about, so it can still uninstall" {
    EXISTING_INSTANCE="true" ARCH="x86_64" DISTRO_VERSION_ID="15.7" run macos_requirements
    assert_success
    assert_output --partial "Going on anyway"
}

@test "macos requirements: the override goes ahead, saying what to expect" {
    OVOS_INSTALLER_ALLOW_UNSUPPORTED_MACOS="true" ARCH="arm64" DISTRO_VERSION_ID="14.6" run macos_requirements
    assert_success
    assert_output --partial "Going on anyway"
}

@test "macos requirements: Linux is not asked" {
    DISTRO_NAME="ubuntu" ARCH="x86_64" DISTRO_VERSION_ID="24.04" run macos_requirements
    assert_success
    assert_output ""
}

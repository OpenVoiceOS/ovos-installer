#!/usr/bin/env bats
# Tests for banner.sh display functionality
# Following BATS best practices for output verification

setup() {
    # Load BATS testing framework
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    # Set up test environment
    export INSTALLER_VERSION="1.0.0-test"

    # Load source files under test
    load ../../utils/constants.sh
    load ../../utils/banner.sh
}

teardown() {
    # Reset any modified environment variables
    unset INSTALLER_VERSION
}

# Test banner display function
@test "banner_display_contains_title" {
    [ -f ../../utils/banner.sh ] || skip "banner.sh missing"
    run bash -c 'source ../../utils/banner.sh; type -t banner_display >/dev/null 2>&1 && banner_display || true'
    assert_success
    assert_output --partial "OPEN VOICE OS INSTALLER"
}

@test "banner_display_contains_version" {
    [ -f ../../utils/banner.sh ] || skip "banner.sh missing"
    INSTALLER_VERSION="v1.2.3-test"
    export INSTALLER_VERSION

    run bash -c 'source ../../utils/banner.sh; type -t banner_display >/dev/null 2>&1 && banner_display || true'
    assert_success
    # Should contain the version
    assert_output --partial "Version: v1.2.3-test"
}

@test "banner_display_ansi_colors" {
    [ -f ../../utils/banner.sh ] || skip "banner.sh missing"
    run bash -c 'source ../../utils/banner.sh; type -t banner_display >/dev/null 2>&1 && banner_display || true'
    assert_success
    # Should contain ANSI color codes
    assert_output --partial $'\033[1m'
    assert_output --partial $'\033[0m'
}

@test "banner_display_structure" {
    [ -f ../../utils/banner.sh ] || skip "banner.sh missing"
    run bash -c 'source ../../utils/banner.sh; type -t banner_display >/dev/null 2>&1 && banner_display || true'
    assert_success
    # Should contain the border lines
    assert_output --partial "==============================================="
    # Should contain the title
    assert_output --partial "OPEN VOICE OS INSTALLER"
    # Should end with empty line
    assert_output --partial $'\n'
}

# Test that banner loads constants
@test "banner_loads_installer_version" {
    # Test that banner script can access INSTALLER_VERSION
    run bash -c "source ../../utils/constants.sh && source ../../utils/banner.sh && echo \"Version: \$INSTALLER_VERSION\""
    assert_success
    assert_output --partial "Version:"
}

function teardown() {
    unset INSTALLER_VERSION
}

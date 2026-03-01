#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    RUN_AS="testuser"
    RASPBERRYPI_MODEL="N/A"
}

# Test avrdude setup function
@test "function_setup_avrdude_file_creation" {
    AVRDUDE_BINARY_PATH=/tmp/test_avrdude
    RUN_AS_HOME=/tmp/test_home
    mkdir -p "$RUN_AS_HOME"

    function curl() {
        # Mock successful curl download
        touch "$AVRDUDE_BINARY_PATH"
        return 0
    }
    export -f curl

    run setup_avrdude
    assert_success
    # Should create avrdude binary
    [ -f "$AVRDUDE_BINARY_PATH" ]
    # Should create avrduderc file
    [ -f "$RUN_AS_HOME/.avrduderc" ]

    # Clean up
    rm -f "$AVRDUDE_BINARY_PATH" "$RUN_AS_HOME/.avrduderc"
    rmdir "$RUN_AS_HOME"
}

@test "function_setup_avrdude_existing_file_removal" {
    AVRDUDE_BINARY_PATH=/tmp/test_avrdude
    RUN_AS_HOME=/tmp/test_home
    mkdir -p "$RUN_AS_HOME"

    # Create existing file
    touch "$AVRDUDE_BINARY_PATH"

    function curl() {
        # Mock successful curl download - recreate the file
        touch "$AVRDUDE_BINARY_PATH"
        return 0
    }
    export -f curl

    run setup_avrdude
    assert_success
    # Should still have created the avrdude binary
    [ -f "$AVRDUDE_BINARY_PATH" ]
    # Should create avrduderc file
    [ -f "$RUN_AS_HOME/.avrduderc" ]

    # Clean up
    rm -f "$AVRDUDE_BINARY_PATH" "$RUN_AS_HOME/.avrduderc"
    rmdir "$RUN_AS_HOME"
    unset -f curl
}



# Test I2C scan function
@test "function_i2c_scan_raspberry_pi_detected" {
    RASPBERRYPI_MODEL="Raspberry Pi 4"

    function dtparam() {
        return 0
    }
    function lsmod() {
        return 0
    }
    function i2c_get() {
        return 1  # No devices detected
    }
    export -f dtparam lsmod i2c_get

    run i2c_scan
    assert_success
}

@test "function_i2c_scan_not_raspberry_pi" {
    RASPBERRYPI_MODEL="N/A"

    run i2c_scan
    assert_success
    # Should not attempt I2C operations
}

@test "function_enforce_mark2_devkit_trixie_requirement_accepts_debian_trixie" {
    DETECTED_DEVICES=("tas5806")
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"

    run enforce_mark2_devkit_trixie_requirement
    assert_success
}

@test "function_enforce_mark2_alpha_channel_forces_alpha" {
    DETECTED_DEVICES=("tas5806")
    CHANNEL="stable"

    enforce_mark2_alpha_channel
    assert_equal "$CHANNEL" "alpha"
}

@test "function_enforce_mark2_alpha_channel_does_not_force_devkit" {
    DETECTED_DEVICES=("attiny1614" "tas5806")
    CHANNEL="stable"

    enforce_mark2_alpha_channel
    assert_equal "$CHANNEL" "stable"
}

@test "function_enforce_mark2_devkit_gui_support_does_not_force_feature_gui_on_trixie" {
    DETECTED_DEVICES=("tas5806")
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    FEATURE_GUI="false"

    enforce_mark2_devkit_gui_support
    assert_equal "$FEATURE_GUI" "false"
}

@test "function_enforce_mark2_devkit_gui_support_preserves_feature_gui_on_supported_trixie" {
    DETECTED_DEVICES=("tas5806")
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    FEATURE_GUI="true"

    enforce_mark2_devkit_gui_support
    assert_equal "$FEATURE_GUI" "true"
}

@test "function_enforce_mark2_devkit_gui_support_disables_feature_gui_on_non_trixie" {
    DETECTED_DEVICES=("tas5806")
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="12"
    DISTRO_VERSION="Debian GNU/Linux 12 (bookworm)"
    FEATURE_GUI="true"

    enforce_mark2_devkit_gui_support
    assert_equal "$FEATURE_GUI" "false"
}

@test "function_enforce_mark2_devkit_gui_support_sets_feature_gui_false_on_non_trixie_when_unset" {
    DETECTED_DEVICES=("tas5806")
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="12"
    DISTRO_VERSION="Debian GNU/Linux 12 (bookworm)"
    unset FEATURE_GUI

    enforce_mark2_devkit_gui_support
    assert_equal "$FEATURE_GUI" "false"
}

@test "function_enforce_mark2_devkit_gui_support_disables_server_profile" {
    DETECTED_DEVICES=("tas5806")
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    PROFILE="server"
    FEATURE_GUI="true"

    enforce_mark2_devkit_gui_support
    assert_equal "$FEATURE_GUI" "false"
}

@test "function_enforce_mark2_devkit_trixie_requirement_rejects_non_trixie" {
    DETECTED_DEVICES=("tas5806")
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="12"
    DISTRO_VERSION="Debian GNU/Linux 12 (bookworm)"

    run enforce_mark2_devkit_trixie_requirement
    assert_failure
    assert_equal "$status" "$EXIT_OS_NOT_SUPPORTED"
    assert_output --partial "Mark II/DevKit requires Debian Trixie (13)."
}

# Test apt_ensure function
@test "function_apt_ensure_all_packages_installed" {
    function dpkg-query() {
        # Mock all packages as installed
        echo "install ok installed"
    }
    export -f dpkg-query

    run apt_ensure "git" "curl" "htop"
    assert_success
    # Should not attempt installation
}



# Test state directory function
@test "function_state_directory_creation" {
    RUN_AS_HOME=/tmp/test_home
    mkdir -p "$RUN_AS_HOME"

    run state_directory
    assert_success
    # Should create the directory structure
    [ -d "$RUN_AS_HOME/.local/state/ovos" ]

    # Clean up
    rm -rf "$RUN_AS_HOME"
}

@test "function_state_directory_existing" {
    RUN_AS_HOME=/tmp/test_home
    mkdir -p "$RUN_AS_HOME/.local/state/ovos"

    run state_directory
    assert_success
    # Should still work with existing directory
    [ -d "$RUN_AS_HOME/.local/state/ovos" ]

    # Clean up
    rm -rf "$RUN_AS_HOME"
}

# Test apt_ensure more thoroughly
@test "function_apt_ensure_mixed_packages" {
    UPDATE=1
    export UPDATE

    function dpkg-query() {
        if [[ "$1" == "git" ]]; then
            echo "install ok installed"
        elif [[ "$1" == "curl" ]]; then
            echo ""
        fi
    }
    function sudo() {
        # Mock sudo
        "$@"
    }
    function apt() {
        # Mock apt install
        return 0
    }
    export -f dpkg-query sudo apt

    run apt_ensure "git" "curl"
    assert_success
    unset -f dpkg-query sudo apt
    unset UPDATE
}

function teardown() {
    rm -f "$LOG_FILE"
    unset DETECTED_DEVICES AVRDUDE_BINARY_PATH RUN_AS_HOME RASPBERRYPI_MODEL FEATURE_GUI PROFILE DISTRO_NAME DISTRO_VERSION_ID DISTRO_VERSION
}

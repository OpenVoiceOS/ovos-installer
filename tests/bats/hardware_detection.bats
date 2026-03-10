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

function mock_curl_touch_output() {
    local output=""
    while [ "$#" -gt 0 ]; do
        if [ "$1" == "-o" ]; then
            output="$2"
            break
        fi
        shift
    done

    if [ -z "$output" ]; then
        printf '%s\n' "mock_curl_touch_output: missing -o output path" >&2
        return 1
    fi

    touch "$output"
    return 0
}

# Test avrdude setup function
@test "function_setup_avrdude_file_creation" {
    AVRDUDE_BINARY_PATH=/tmp/test_avrdude
    AVRDUDE_CONFIG_PATH=/tmp/test_avrdude.conf
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"

    function detect_libgpiod_abi() {
        printf '%s\n' "3"
    }
    function curl() {
        mock_curl_touch_output "$@"
    }
    function chown() {
        return 0
    }
    export -f detect_libgpiod_abi curl chown

    run setup_avrdude
    assert_success
    # Should create avrdude binary
    [ -f "$AVRDUDE_BINARY_PATH" ]
    # Should create avrduderc file
    [ -f "$RUN_AS_HOME/.avrduderc" ]
    # Should create avrdude config file
    [ -f "$AVRDUDE_CONFIG_PATH" ]

    # Clean up
    rm -f "$AVRDUDE_BINARY_PATH" "$AVRDUDE_CONFIG_PATH" "$RUN_AS_HOME/.avrduderc"
    rm -rf "$RUN_AS_HOME"
    unset -f detect_libgpiod_abi curl chown
}

@test "function_setup_avrdude_existing_file_removal" {
    AVRDUDE_BINARY_PATH=/tmp/test_avrdude
    AVRDUDE_CONFIG_PATH=/tmp/test_avrdude.conf
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"

    # Create existing file
    touch "$AVRDUDE_BINARY_PATH"

    function detect_libgpiod_abi() {
        printf '%s\n' "3"
    }
    function curl() {
        mock_curl_touch_output "$@"
    }
    function chown() {
        return 0
    }
    export -f detect_libgpiod_abi curl chown

    run setup_avrdude
    assert_success
    # Should still have created the avrdude binary
    [ -f "$AVRDUDE_BINARY_PATH" ]
    # Should create avrduderc file
    [ -f "$RUN_AS_HOME/.avrduderc" ]

    # Clean up
    rm -f "$AVRDUDE_BINARY_PATH" "$AVRDUDE_CONFIG_PATH" "$RUN_AS_HOME/.avrduderc"
    rm -rf "$RUN_AS_HOME"
    unset -f detect_libgpiod_abi curl chown
}

@test "function_detect_mark1_device_skips_unusable_avrdude" {
    AVRDUDE_BINARY_PATH=/tmp/test_avrdude
    AVRDUDE_CONFIG_PATH=/tmp/test_avrdude.conf
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"
    DETECTED_DEVICES=()
    : >"$LOG_FILE"

    function curl() {
        local output=""
        while [ "$#" -gt 0 ]; do
            if [ "$1" == "-o" ]; then
                output="$2"
                break
            fi
            shift
        done

        if [ "$output" == "$AVRDUDE_BINARY_PATH" ]; then
            cat <<'EOF' >"$output"
#!/usr/bin/env bash
echo "avrdude: error while loading shared libraries: libgpiod.so.2: cannot open shared object file: No such file or directory" >&2
exit 127
EOF
            return 0
        fi

        mock_curl_touch_output "$@"
    }
    function detect_libgpiod_abi() {
        printf '%s\n' "3"
    }
    function chown() {
        return 0
    }
    function avrdude() {
        echo "unexpected PATH avrdude invocation" >&2
        return 99
    }
    export -f curl detect_libgpiod_abi chown avrdude

    run detect_mark1_device
    assert_success

    run has_detected_device "atmega328p"
    assert_failure

    run grep -F -q "[warn] Skipping Mark 1 AVR probe because avrdude is unusable on this host." "$LOG_FILE"
    assert_success

    run grep -F -q "unexpected PATH avrdude invocation" "$LOG_FILE"
    assert_failure

    rm -f "$AVRDUDE_BINARY_PATH" "$AVRDUDE_CONFIG_PATH" "$RUN_AS_HOME/.avrduderc"
    rm -rf "$RUN_AS_HOME"
    unset -f curl detect_libgpiod_abi chown avrdude
}

@test "function_detect_libgpiod_abi_prefers_ldconfig" {
    function ldconfig() {
        cat <<'EOF'
libgpiod.so.3 (libc6,AArch64) => /lib/aarch64-linux-gnu/libgpiod.so.3
libgpiod.so.2 (libc6,AArch64) => /lib/aarch64-linux-gnu/libgpiod.so.2
EOF
    }
    export -f ldconfig

    run detect_libgpiod_abi
    assert_success
    assert_output "3"

    unset -f ldconfig
}

@test "function_resolve_avrdude_artifact_urls_uses_gpiod3_bundle" {
    AVRDUDE_ARTIFACT_BASE_URL="https://artifacts.smartgic.io/avrdude"
    AVRDUDE_ARTIFACT_VERSION="v8.1"
    AVRDUDE_ARTIFACT_ARCH="aarch64"

    function detect_libgpiod_abi() {
        printf '%s\n' "3"
    }
    function resolve_avrdude_artifact_urls_and_print() {
        resolve_avrdude_artifact_urls || return 1
        printf '%s\n' "$AVRDUDE_BINARY_URL"
        printf '%s\n' "$AVRDUDE_CONFIG_URL"
    }
    export -f detect_libgpiod_abi resolve_avrdude_artifact_urls_and_print

    run resolve_avrdude_artifact_urls_and_print
    assert_success
    assert_line --index 0 "https://artifacts.smartgic.io/avrdude/v8.1/aarch64/libgpiod3/avrdude"
    assert_line --index 1 "https://artifacts.smartgic.io/avrdude/v8.1/aarch64/libgpiod3/avrdude.conf"

    unset -f detect_libgpiod_abi resolve_avrdude_artifact_urls_and_print
}

@test "function_setup_avrdude_fails_without_supported_artifact" {
    AVRDUDE_BINARY_PATH=/tmp/test_avrdude
    AVRDUDE_CONFIG_PATH=/tmp/test_avrdude.conf
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"
    : >"$LOG_FILE"

    function detect_libgpiod_abi() {
        return 1
    }
    function chown() {
        return 0
    }
    export -f detect_libgpiod_abi chown

    run setup_avrdude
    assert_failure
    run grep -F -q "[warn] Failed to resolve avrdude artifact bundle for Mark 1 detection." "$LOG_FILE"
    assert_success

    rm -f "$AVRDUDE_BINARY_PATH" "$AVRDUDE_CONFIG_PATH" "$RUN_AS_HOME/.avrduderc"
    rm -rf "$RUN_AS_HOME"
    unset -f detect_libgpiod_abi chown
}

@test "function_setup_avrdude_uses_selected_bundle_without_legacy_fallback" {
    AVRDUDE_BINARY_PATH=/tmp/test_avrdude
    AVRDUDE_CONFIG_PATH=/tmp/test_avrdude.conf
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"
    : >"$LOG_FILE"

    function detect_libgpiod_abi() {
        printf '%s\n' "3"
    }
    function curl() {
        local url=""
        local -a args=("$@")
        while [ "$#" -gt 0 ]; do
            if [[ "$1" == http* ]]; then
                url="$1"
            fi
            shift
        done

        if [[ "$url" != *"/libgpiod3/avrdude" && "$url" != *"/libgpiod3/avrdude.conf" ]]; then
            return 22
        fi

        mock_curl_touch_output "${args[@]}"
        return 0
    }
    function chown() {
        return 0
    }
    export -f detect_libgpiod_abi curl chown

    setup_avrdude
    assert_equal "$?" "0"
    assert_equal "$AVRDUDE_BINARY_URL" "https://artifacts.smartgic.io/avrdude/v8.1/aarch64/libgpiod3/avrdude"
    assert_equal "$AVRDUDE_CONFIG_URL" "https://artifacts.smartgic.io/avrdude/v8.1/aarch64/libgpiod3/avrdude.conf"

    rm -f "$AVRDUDE_BINARY_PATH" "$AVRDUDE_CONFIG_PATH" "$RUN_AS_HOME/.avrduderc"
    rm -rf "$RUN_AS_HOME"
    unset -f detect_libgpiod_abi curl chown
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
    function modprobe() {
        return 0
    }
    function i2c_get() {
        return 1  # No devices detected
    }
    export -f dtparam lsmod modprobe i2c_get

    run i2c_scan
    assert_success
}

@test "function_i2c_scan_does_not_restore_cached_mark2_state_when_live_scan_misses" {
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    DISPLAY_SERVER="N/A"
    CHANNEL="testing"
    PROFILE="ovos"
    FEATURE_GUI="false"
    EXISTING_INSTANCE="true"
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"
    mkdir -p "$RUN_AS_HOME/.local/state/ovos"
    cat >"$RUN_AS_HOME/.local/state/ovos/installer.json" <<'EOF'
{"i2c_devices":["tas5806"]}
EOF
    DETECTED_DEVICES=()

    function dtparam() {
        return 0
    }
    function lsmod() {
        return 0
    }
    function modprobe() {
        return 0
    }
    function i2c_get() {
        return 1
    }
    export -f dtparam lsmod modprobe i2c_get

    i2c_scan
    assert_equal "$?" "0"

    run has_detected_device "tas5806"
    assert_failure
    assert_equal "$DISPLAY_SERVER" "N/A"
    assert_equal "$CHANNEL" "testing"

    rm -rf "$RUN_AS_HOME"
}

@test "function_i2c_scan_does_not_restore_cached_mark2_state_on_new_install" {
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    DISPLAY_SERVER="N/A"
    CHANNEL="testing"
    PROFILE="ovos"
    FEATURE_GUI="false"
    EXISTING_INSTANCE="false"
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"
    mkdir -p "$RUN_AS_HOME/.local/state/ovos"
    cat >"$RUN_AS_HOME/.local/state/ovos/installer.json" <<'EOF'
{"i2c_devices":["tas5806"]}
EOF
    DETECTED_DEVICES=()

    function dtparam() {
        return 0
    }
    function lsmod() {
        return 0
    }
    function modprobe() {
        return 0
    }
    function i2c_get() {
        return 1
    }
    export -f dtparam lsmod modprobe i2c_get

    i2c_scan
    assert_equal "$?" "0"

    run has_detected_device "tas5806"
    assert_failure
    assert_equal "$DISPLAY_SERVER" "N/A"
    assert_equal "$CHANNEL" "testing"

    rm -rf "$RUN_AS_HOME"
}

@test "function_i2c_scan_not_raspberry_pi" {
    RASPBERRYPI_MODEL="N/A"

    run i2c_scan
    assert_success
    # Should not attempt I2C operations
}

@test "function_i2c_scan_ignores_non_primary_bus_false_positives_by_default" {
    run bash -lc "
        source '$BATS_TEST_DIRNAME/../../utils/constants.sh'
        source '$BATS_TEST_DIRNAME/../../utils/common.sh'
        LOG_FILE=\"\$(mktemp /tmp/ovos-installer-bats.XXXXXX)\"
        RASPBERRYPI_MODEL='Raspberry Pi 5'
        I2C_BUS='1'
        DISTRO_NAME='debian'
        DISTRO_VERSION_ID='13'
        DISTRO_VERSION='Debian GNU/Linux 13 (trixie)'
        DISPLAY_SERVER='N/A'
        CHANNEL='testing'
        FEATURE_GUI='false'
        DETECTED_DEVICES=()

        dtparam() { return 0; }
        lsmod() { return 0; }
        modprobe() { return 0; }
        i2cdetect() {
            printf 'i2c-bus:%s\n' \"\$3\" >>\"\$LOG_FILE\"
            if [[ \"\$3\" == '13' ]]; then
                printf '%s\n' '2f'
            else
                printf '\n'
            fi
        }
        export -f dtparam lsmod modprobe i2cdetect

        i2c_scan >/dev/null
        if has_detected_device 'tas5806'; then
            printf '%s\n' 'tas5806:present'
        else
            printf '%s\n' 'tas5806:absent'
        fi
        printf 'feature_gui:%s\n' \"\$FEATURE_GUI\"
        printf 'channel:%s\n' \"\$CHANNEL\"
        grep -o 'i2c-bus:[0-9]\\+' \"\$LOG_FILE\" | sort -u
    "
    assert_success
    assert_output --partial "tas5806:absent"
    assert_output --partial "feature_gui:false"
    assert_output --partial "channel:testing"
    assert_output --partial "i2c-bus:1"
}

@test "function_enforce_mark2_devkit_trixie_requirement_accepts_debian_trixie" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"

    run enforce_mark2_devkit_trixie_requirement
    assert_success
}

@test "function_has_detected_device_handles_unset_detected_devices" {
    unset DETECTED_DEVICES

    run has_detected_device "tas5806"
    assert_failure
}

@test "function_enforce_mark2_alpha_channel_forces_alpha" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    CHANNEL="testing"

    enforce_mark2_alpha_channel
    assert_equal "$CHANNEL" "alpha"
}

@test "function_enforce_mark2_alpha_channel_is_silent" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    CHANNEL="testing"

    run enforce_mark2_alpha_channel
    assert_success
    assert_output ""
}

@test "function_enforce_mark2_alpha_channel_forces_alpha_on_devkit" {
    DETECTED_DEVICES=("attiny1614" "tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    CHANNEL="testing"

    enforce_mark2_alpha_channel
    assert_equal "$CHANNEL" "alpha"
}

@test "function_enforce_mark2_devkit_gui_support_does_not_force_feature_gui_on_trixie" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    FEATURE_GUI="false"

    enforce_mark2_devkit_gui_support
    assert_equal "$FEATURE_GUI" "false"
}

@test "function_enforce_mark2_devkit_gui_support_preserves_feature_gui_on_supported_trixie" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    FEATURE_GUI="true"

    enforce_mark2_devkit_gui_support
    assert_equal "$FEATURE_GUI" "true"
}

@test "function_enforce_mark2_devkit_gui_support_disables_feature_gui_on_non_trixie" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="12"
    DISTRO_VERSION="Debian GNU/Linux 12 (bookworm)"
    FEATURE_GUI="true"

    enforce_mark2_devkit_gui_support
    assert_equal "$FEATURE_GUI" "false"
}

@test "function_enforce_mark2_devkit_gui_support_sets_feature_gui_false_on_non_trixie_when_unset" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="12"
    DISTRO_VERSION="Debian GNU/Linux 12 (bookworm)"
    unset FEATURE_GUI

    enforce_mark2_devkit_gui_support
    assert_equal "$FEATURE_GUI" "false"
}

@test "function_enforce_mark2_devkit_gui_support_disables_server_profile" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    PROFILE="server"
    FEATURE_GUI="true"

    enforce_mark2_devkit_gui_support
    assert_equal "$FEATURE_GUI" "false"
}

@test "function_enforce_mark2_devkit_display_server_sets_eglfs_for_headless" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISPLAY_SERVER="N/A"

    enforce_mark2_devkit_display_server
    assert_equal "$DISPLAY_SERVER" "eglfs"
}

@test "function_enforce_mark2_devkit_display_server_is_silent" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISPLAY_SERVER="N/A"

    run enforce_mark2_devkit_display_server
    assert_success
    assert_output ""
}

@test "function_enforce_mark2_devkit_display_server_keeps_detected_compositor" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISPLAY_SERVER="wayland"

    enforce_mark2_devkit_display_server
    assert_equal "$DISPLAY_SERVER" "wayland"
}

@test "function_enforce_mark2_devkit_trixie_requirement_rejects_non_trixie" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="12"
    DISTRO_VERSION="Debian GNU/Linux 12 (bookworm)"

    run enforce_mark2_devkit_trixie_requirement
    assert_failure
    assert_equal "$status" "$EXIT_OS_NOT_SUPPORTED"
    assert_output --partial "Mark II/DevKit requires Debian Trixie (13)."
}

@test "function_is_mark2_or_devkit_detected_requires_raspberry_pi_4" {
    DETECTED_DEVICES=("tas5806")
    RASPBERRYPI_MODEL="Raspberry Pi 5"

    run is_mark2_or_devkit_detected
    assert_failure
}

@test "function_detect_devkit_device_ignores_tas5806_hits_on_unsupported_boards" {
    RASPBERRYPI_MODEL="Raspberry Pi 5"
    DETECTED_DEVICES=()
    : >"$LOG_FILE"

    function i2c_get() {
        return 0
    }
    export -f i2c_get

    run detect_devkit_device
    assert_success

    run has_detected_device "tas5806"
    assert_failure

    run has_detected_device "attiny1614"
    assert_failure

    run grep -q "Ignoring tas5806/attiny1614 detection on unsupported board" "$LOG_FILE"
    assert_success

    unset -f i2c_get
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
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"

    run state_directory
    assert_success
    # Should create the directory structure
    [ -d "$RUN_AS_HOME/.local/state/ovos" ]

    # Clean up
    rm -rf "$RUN_AS_HOME"
}

@test "function_state_directory_existing" {
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"
    mkdir -p "$RUN_AS_HOME/.local/state/ovos"

    run state_directory
    assert_success
    # Should still work with existing directory
    [ -d "$RUN_AS_HOME/.local/state/ovos" ]

    # Clean up
    rm -rf "$RUN_AS_HOME"
}

@test "function_state_directory_persists_detected_i2c_devices" {
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"
    RUN_AS="$(id -un)"
    RUN_AS_GROUP="$(id -gn)"
    DETECTED_DEVICES=("tas5806" "attiny1614")

    state_directory
    assert_equal "$?" "0"

    run jq -e '(.i2c_devices | sort) == ["attiny1614","tas5806"]' "$RUN_AS_HOME/.local/state/ovos/installer.json"
    assert_success

    rm -rf "$RUN_AS_HOME"
}

@test "function_state_directory_clears_persisted_i2c_devices_when_none_are_detected" {
    RUN_AS_HOME="$(mktemp -d /tmp/ovos-installer-bats.XXXXXX)"
    RUN_AS="$(id -un)"
    RUN_AS_GROUP="$(id -gn)"
    mkdir -p "$RUN_AS_HOME/.local/state/ovos"
    cat >"$RUN_AS_HOME/.local/state/ovos/installer.json" <<'EOF'
{"i2c_devices":["tas5806"]}
EOF
    DETECTED_DEVICES=()

    state_directory
    assert_equal "$?" "0"

    run jq -e '.i2c_devices == []' "$RUN_AS_HOME/.local/state/ovos/installer.json"
    assert_success

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
    unset DETECTED_DEVICES AVRDUDE_BINARY_PATH RUN_AS_HOME RASPBERRYPI_MODEL FEATURE_GUI PROFILE DISTRO_NAME DISTRO_VERSION_ID DISTRO_VERSION DISPLAY_SERVER
}

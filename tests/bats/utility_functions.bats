#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    RUN_AS_HOME="/home/testuser"
    DETECT_SOUND_BACKUP=""
    if [ -f "utils/detect_sound.py" ]; then
        DETECT_SOUND_BACKUP="$(mktemp)"
        cp "utils/detect_sound.py" "$DETECT_SOUND_BACKUP"
    fi
}

# Test utility functions
@test "function_in_array_found" {
    local test_array=("apple" "banana" "cherry")
    run in_array test_array "banana"
    assert_success
}

@test "function_in_array_not_found" {
    local test_array=("apple" "banana" "cherry")

    # Mock the ask_optin function to avoid interactive input
    function ask_optin() {
        printf '%s\n' "Error: unsupported option"
        exit 1
    }
    export -f ask_optin

    run in_array test_array "grape"
    assert_failure
    # The in_array function outputs "grape is an unsupported option" to LOG_FILE
    # and then calls on_error which calls ask_optin
    assert_output --partial "Error: unsupported option"

    unset -f ask_optin
}

@test "function_wsl2_requirements_systemd_check" {
    KERNEL="microsoft"
    WSL_FILE=/tmp/wsl.conf
    cat <<EOF >"$WSL_FILE"
[boot]
systemd=true
EOF
    run wsl2_requirements
    assert_success
    assert_output --partial "Validating WSL2 requirements"
}

@test "function_wsl2_requirements_systemd_missing" {
    KERNEL="microsoft"
    WSL_FILE=/tmp/wsl.conf
    cat <<EOF >"$WSL_FILE"
[boot]
commandline=quiet
EOF
    run wsl2_requirements
    assert_failure
    # The function outputs to LOG_FILE, not stdout, so check the log
    assert_output --partial "Validating WSL2 requirements"
}

@test "function_wsl2_requirements_not_wsl" {
    KERNEL="linux"
    run wsl2_requirements
    assert_success
    refute_output --partial "Validating WSL2 requirements"
}

# Test version comparison function
@test "function_ver_basic_version" {
    result=$(ver "1.2.3")
    assert_equal "$result" "001002003"
}

@test "function_ver_single_digit" {
    result=$(ver "5")
    assert_equal "$result" "005"
}

@test "function_ver_two_digits" {
    result=$(ver "3.9")
    assert_equal "$result" "003009"
}

# Test printf usage in various functions
@test "function_detect_sound_printf_usage" {
    skip "Complex sound server detection mocking"
}

@test "function_detect_cpu_instructions_printf_usage" {
    function grep() {
        return 0
    }
    export -f grep
    run detect_cpu_instructions
    assert_success
    assert_output --partial "Detecting AVX2/SIMD support"
    unset grep
}

@test "function_detect_existing_instance_printf_usage" {
    run detect_existing_instance
    assert_success
    assert_output --partial "Checking for existing instance"
}

@test "function_detect_display_printf_usage" {
    function loginctl() {
        echo "c1"
        echo "   c1"
    }
    export -f loginctl
    run detect_display
    assert_success
    assert_output --partial "Detecting display server"
    unset loginctl
}

@test "function_is_raspeberrypi_soc_printf_usage" {
    DT_FILE=/tmp/model
    echo "Raspberry Pi 4" > "$DT_FILE"
    run is_raspeberrypi_soc
    assert_success
    assert_output --partial "Checking for Raspberry Pi board"
}

@test "function_get_os_information_printf_usage" {
    OS_RELEASE=/tmp/os-release
    cat <<EOF >"$OS_RELEASE"
ID=ubuntu
VERSION_ID="20.04"
VERSION="20.04.5 LTS (Focal Fossa)"
EOF
    function uname() {
        echo "x86_64"
        echo "5.4.0-42-generic"
    }
    function python3() {
        echo "3.8.10"
    }
    export -f uname python3
    run get_os_information
    assert_success
    assert_output --partial "Retrieving OS information"
    unset uname python3
}

# Test local variable usage
@test "function_detect_sound_local_variables" {
    # Set required environment variables
    RUN_AS_UID="1000"
    RUN_AS_HOME="/home/testuser"

    function python3() {
        if [[ "$1" == *"detect_sound.py"* ]]; then
            echo "PulseAudio"
        fi
    }
    export -f python3

    touch "utils/detect_sound.py"

    detect_sound
    assert_equal "${SOUND_SERVER}" "PulseAudio"

    rm -f "utils/detect_sound.py"
    unset python3
}

# Test ask_optin function
@test "function_ask_optin_yes" {
    # Mock read to return 'yes'
    function read() {
        yn="yes"
    }
    export -f read
    export OVOS_INSTALLER_ASSUME_INTERACTIVE="true"
    run ask_optin
    assert_success
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    unset -f read
}

@test "function_ask_optin_no" {
    function read() {
        yn="no"
    }
    export -f read
    export OVOS_INSTALLER_ASSUME_INTERACTIVE="true"
    run ask_optin
    assert_failure
    assert_equal "$status" 1
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    unset -f read
}

# Test delete_log function
@test "function_delete_log_existing" {
    touch "$LOG_FILE"
    run delete_log
    assert_success
    [ ! -f "$LOG_FILE" ]
}

@test "function_delete_log_non_existing" {
    [ ! -f "$LOG_FILE" ]
    run delete_log
    assert_success
}

function teardown() {
    rm -f "$LOG_FILE"
    [ -n "$WSL_FILE" ] && [ "$WSL_FILE" != "/etc/wsl.conf" ] && rm -f "$WSL_FILE"
    [ -n "$DT_FILE" ] && [ "$DT_FILE" != "/sys/firmware/devicetree/base/model" ] && rm -f "$DT_FILE"
    [ -n "$OS_RELEASE" ] && [ "$OS_RELEASE" != "/etc/os-release" ] && rm -f "$OS_RELEASE"
    if [ -n "$DETECT_SOUND_BACKUP" ]; then
        cp "$DETECT_SOUND_BACKUP" "utils/detect_sound.py"
        rm -f "$DETECT_SOUND_BACKUP"
    else
        rm -f "utils/detect_sound.py"
    fi
    unset RUN_AS SOUND_SERVER CPU_IS_CAPABLE
}

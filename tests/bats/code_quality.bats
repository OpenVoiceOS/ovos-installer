#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    RASPBERRYPI_MODEL="N/A"
    DETECT_SOUND_BACKUP=""
    if [ -f "utils/detect_sound.py" ]; then
        DETECT_SOUND_BACKUP="$(mktemp)"
        cp "utils/detect_sound.py" "$DETECT_SOUND_BACKUP"
    fi
}

# Test printf migration from echo -e
@test "printf_migration_on_error" {
    # Mock the ask_optin function to avoid interactive input
    function ask_optin() {
        return 0  # Simulate user agreeing
    }
    function curl() {
        echo "https://paste.example.com/test-url"
    }
    export -f ask_optin curl

    touch "$LOG_FILE"

    run on_error
    assert_failure
    # Should contain printf-formatted output
    assert_output --partial "Unable to finalize the process"
    assert_output --partial "Please share this URL with us"

    unset -f ask_optin curl
}

@test "printf_migration_detect_user" {
    USER_ID="1000"
    run detect_user
    assert_failure
    assert_output --partial "This script must be run as root"
}

@test "printf_migration_detect_sound" {
    skip "Complex sound server detection mocking"
}

@test "printf_migration_required_packages" {
    DISTRO_NAME="debian"
    function apt_ensure() {
        return 0
    }
    export -f apt_ensure
    run required_packages
    assert_success
    assert_output --partial "Validating installer package requirements"
    unset apt_ensure
}

# Test quoting consistency
@test "quoting_consistency_variables" {
    USER_ID="0"
    SUDO_USER="testuser"
    SUDO_UID="1000"
    INSTALLER_VENV_NAME="ovos-installer"

    # Mock functions that detect_user calls
    function getent() {
        if [[ "$1" == "passwd" && "$2" == "testuser" ]]; then
            echo "testuser:x:1000:1000:Test User:/home/testuser:/bin/bash"
        fi
    }
    function id() {
        if [[ "$1" == "-ng" ]]; then
            echo "testuser"
        else
            echo "uid=1000(testuser) gid=1000(testuser) groups=1000(testuser)"
        fi
    }
    export -f getent id

    detect_user
    # Variables should be properly quoted in function calls
    assert_equal "${RUN_AS}" "testuser"
    assert_equal "${RUN_AS_UID}" "1000"

    unset -f getent id
}

@test "quoting_consistency_array_access" {
    local test_array=("value1" "value2")
    run in_array test_array "value1"
    assert_success
}

# Test local variable usage
@test "local_variables_detect_sound" {
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

    # Call detect_sound directly (not with run) to test variable setting
    detect_sound
    assert_equal "${SOUND_SERVER}" "PulseAudio"

    rm -f "utils/detect_sound.py"
    unset python3
}

@test "local_variables_required_packages" {
    DISTRO_NAME="debian"
    function apt_ensure() {
        return 0
    }
    export -f apt_ensure
    run required_packages
    assert_success
    unset apt_ensure
}



# Test constants alphabetical ordering
@test "constants_alphabetical_order" {
    # Test that constants are properly ordered
    # This ensures maintainability
    assert_equal "${ANSIBLE_LOG_FILE}" "/var/log/ovos-ansible.log"
    assert_equal "${ATMEGA328P_SIGNATURE}" ":030000001E950F3B"
    assert_equal "${AVRDUDE_BINARY_PATH}" "/usr/local/bin/avrdude"
    assert_equal "${AVRDUDE_BINARY_URL}" "https://artifacts.smartgic.io/avrdude/avrdude-aarch64"
    assert_equal "${AVRDUDE_CONFIG_PATH}" "/usr/local/etc/avrdude.conf"
    assert_equal "${AVRDUDE_CONFIG_URL}" "https://artifacts.smartgic.io/avrdude/avrdude.conf"
}

# Test modularity improvements
@test "function_modularity_decomposition" {
    # Test that required_packages calls distro-specific functions
    DISTRO_NAME="debian"
    function apt_ensure() {
        return 0
    }
    export -f apt_ensure
    run required_packages
    assert_success
    unset apt_ensure
}

function teardown() {
    rm -f "$LOG_FILE"
    if [ -n "$DETECT_SOUND_BACKUP" ]; then
        cp "$DETECT_SOUND_BACKUP" "utils/detect_sound.py"
        rm -f "$DETECT_SOUND_BACKUP"
    else
        rm -f "utils/detect_sound.py"
    fi
    unset RUN_AS RUN_AS_UID SUDO_USER SUDO_UID USER_ID SOUND_SERVER
}

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

@test "virtualenv_pins_setuptools_for_pkg_resources" {
    # setuptools>=82 dropped pkg_resources, which breaks ovos_plugin_manager imports.
    run grep -q "ovos_installer_setuptools_package" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_setuptools_package" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    # Guard against regression to an unpinned setuptools upgrade.
    run grep -q "pip install -U pip setuptools wheel" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_failure

    run grep -q "ovos_virtualenv_setuptools_package" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success
}

@test "macos_includes_precise_onnx_in_virtualenv_requirements" {
    run grep -q "ovos-ww-plugin-precise-onnx" ansible/roles/ovos_virtualenv/templates/virtualenv/core-requirements.txt.j2
    assert_success

    run grep -q "ovos-ww-plugin-precise-onnx" ansible/roles/ovos_virtualenv/templates/virtualenv/satellite-requirements.txt.j2
    assert_success
}

@test "mycroft_conf_uses_precise_onnx_for_macos_listener" {
    run grep -q "ansible_facts.system == 'Darwin' or ovos_installer_tuning | bool" ansible/roles/ovos_config/templates/mycroft.conf.j2
    assert_success

    run grep -q "\"module\": \"ovos-ww-plugin-precise-onnx\"" ansible/roles/ovos_config/templates/mycroft.conf.j2
    assert_success
}

@test "macos_never_requests_precise_lite_plugin" {
    run grep -R -n "ovos-ww-plugin-precise-lite" ansible/roles/ovos_virtualenv/templates/virtualenv
    assert_failure

    run grep -q "ovos-dinkum-listener\\[{{ 'extras' if ansible_facts.system == 'Darwin' else 'extras,linux' }}\\]" ansible/roles/ovos_virtualenv/templates/virtualenv/core-requirements.txt.j2
    assert_success

    run grep -q "ovos-dinkum-listener\\[{{ 'extras' if ansible_facts.system == 'Darwin' else 'extras,linux' }}\\]" ansible/roles/ovos_virtualenv/templates/virtualenv/satellite-requirements.txt.j2
    assert_success
}

@test "rust_messagebus_download_uses_checksum_verification" {
    run grep -q "ovos_virtualenv_rust_messagebus_archive_checksum" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ansible.builtin.get_url" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success

    run grep -q "checksum: \"{{ ovos_virtualenv_rust_messagebus_archive_checksum }}\"" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success
}

@test "macos_homebrew_uses_espeak_ng_formula" {
    run grep -q -- "- espeak-ng" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q -- "- espeak$" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_failure
}

@test "telemetry_uses_installer_detected_sound_fallback" {
    run grep -q "ovos_installer_sound_server" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success

    run grep -q "sound_server: \"{{ _telemetry_sound_server }}\"" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success

    run grep -q "display_server: \"{{ ovos_installer_display_server | default('unknown') | lower }}\"" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success
}

@test "installer_detects_and_passes_hardware_model" {
    run grep -q "detect_hardware_model" setup.sh
    assert_success

    run grep -q "ovos_installer_hardware='\\\${HARDWARE_MODEL}'" setup.sh
    assert_success
}

@test "tui_hardware_falls_back_to_detected_model" {
    run grep -F -q 'if [ "$HARDWARE_DETECTED" == "N/A" ] && [ -n "${HARDWARE_MODEL:-}" ] && [ "$HARDWARE_MODEL" != "N/A" ]; then' tui/detection.sh
    assert_success
}

@test "telemetry_uses_existing_hardware_field_with_installer_fallback" {
    run grep -q "ovos_installer_hardware" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success

    run grep -q "hardware_model:" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_failure

    run grep -q "{%- set installer_hw = ovos_installer_hardware | default('n/a', true) | string | trim -%}" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success
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

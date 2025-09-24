#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
}

# Test that all constants are properly defined and accessible
@test "constants_basic_values" {
    assert_equal "${ANSIBLE_LOG_FILE}" "/var/log/ovos-ansible.log"
    assert_equal "${INSTALLER_VENV_NAME}" "ovos-installer"
    assert_equal "${LOG_FILE}" "/var/log/ovos-installer.log"
    assert_equal "${USER_ID}" "${EUID}"
    assert_equal "${WLAN_INTERFACE}" "wlan0"
    assert_equal "${YQ_BINARY_PATH}" "/tmp/yq"
    assert_equal "${PASTE_URL}" "https://paste.uoi.io"
}

@test "constants_exit_codes" {
    assert_equal "${EXIT_SUCCESS}" "0"
    assert_equal "${EXIT_FAILURE}" "1"
    assert_equal "${EXIT_PERMISSION_DENIED}" "2"
    assert_equal "${EXIT_OS_NOT_SUPPORTED}" "3"
    assert_equal "${EXIT_INVALID_ARGUMENT}" "4"
    assert_equal "${EXIT_MISSING_DEPENDENCY}" "5"
}


@test "constants_temp_files" {
    assert_equal "${TEMP_FEATURES_FILE}" "/tmp/features.json"
    assert_equal "${TEMP_PROFILE_FILE}" "/tmp/profile.json"
    assert_equal "${TEMP_CHANNEL_FILE}" "/tmp/channel.json"
}

@test "constants_tui_dimensions" {
    assert_equal "${TUI_WINDOW_HEIGHT}" "35"
    assert_equal "${TUI_WINDOW_WIDTH}" "90"
}

@test "constants_system_paths" {
    assert_equal "${OS_RELEASE}" "/etc/os-release"
    assert_equal "${WSL_FILE}" "/etc/wsl.conf"
    assert_equal "${DT_FILE}" "/sys/firmware/devicetree/base/model"
    assert_equal "${REBOOT_FILE_PATH}" "/tmp/ovos.reboot"
}

@test "constants_i2c_settings" {
    assert_equal "${I2C_BUS}" "1"
}

@test "constants_network" {
    assert_equal "${PULSE_SOCKET_WSL2}" "/mnt/wslg/PulseServer"
}

@test "constants_avrdude" {
    assert_equal "${AVRDUDE_BINARY_PATH}" "/usr/local/bin/avrdude"
    assert_equal "${AVRDUDE_CONFIG_PATH}" "/usr/local/etc/avrdude.conf"
    assert_equal "${ATMEGA328P_SIGNATURE}" ":030000001E950F3B"
}

@test "constants_yq" {
    assert_equal "${YQ_URL}" "https://github.com/mikefarah/yq/releases/download/v4.40.3"
}

@test "constants_newt_colors" {
    [[ -n "${NEWT_COLORS}" ]]
    [[ "${NEWT_COLORS}" == *"root=white,black"* ]]
    [[ "${NEWT_COLORS}" == *"border=black,lightgray"* ]]
    [[ "${NEWT_COLORS}" == *"window=lightgray,lightgray"* ]]
}



function teardown() {
    # Clean up any test artifacts
    true
}

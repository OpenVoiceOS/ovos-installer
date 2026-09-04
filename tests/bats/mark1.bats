#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE="$(mktemp)"
    AVRDUDE_BINARY_PATH="$BATS_TMPDIR/avrdude"
    printf 'binary\n' >"$AVRDUDE_BINARY_PATH"
}

function teardown() {
    rm -f "$LOG_FILE" "$AVRDUDE_BINARY_PATH"
}

@test "avrdude_shared_libraries_present_accepts_a_resolvable_binary" {
    function ldd() {
        printf '%s\n' $'\tlibusb-0.1.so.4 => /lib/libusb-0.1.so.4 (0x00)'
    }
    export -f ldd
    run avrdude_shared_libraries_present
    assert_success
    unset ldd
}

@test "avrdude_shared_libraries_present_reports_the_missing_library" {
    # The libgpiod3 bundle needs libusb-0.1, which Debian 13 does not install
    # by default. See issue #590.
    function ldd() {
        printf '%s\n' $'\tlibusb-0.1.so.4 => not found' $'\tlibc.so.6 => /lib/libc.so.6 (0x00)'
    }
    export -f ldd
    run avrdude_shared_libraries_present
    assert_failure
    assert_output --partial "avrdude"
    assert_output --partial "libusb-0.1.so.4"
    assert_output --partial "libusb-0.1-4"
    unset ldd
}

@test "avrdude_shared_libraries_present_names_every_missing_library" {
    function ldd() {
        printf '%s\n' $'\tlibusb-0.1.so.4 => not found' $'\tlibftdi1.so.2 => not found'
    }
    export -f ldd
    run avrdude_shared_libraries_present
    assert_failure
    assert_output --partial "libusb-0.1-4"
    assert_output --partial "libftdi1-2"
    unset ldd
}

@test "avrdude_shared_libraries_present_does_not_block_when_ldd_is_absent" {
    # Nothing to check against, so this must not become a reason to skip
    # Mark 1 detection.
    run bash -c "
        PATH=/nonexistent
        source utils/constants.sh
        source utils/common.sh
        LOG_FILE='$LOG_FILE'
        AVRDUDE_BINARY_PATH='$AVRDUDE_BINARY_PATH'
        avrdude_shared_libraries_present
    "
    assert_success
}

@test "mark1_detection_installs_the_libgpiod3_avrdude_dependency" {
    run grep -q 'extra_packages+=("libusb-0.1-4")' utils/common.sh
    assert_success
}

@test "mark1_checks_the_serial_device_after_writing_the_boot_config" {
    # Bluetooth owns the PL011 until dtoverlay=miniuart-bt moves it, and that
    # only takes effect on the next boot. Asserting the device before writing
    # the overlay makes a freshly flashed card unbootstrappable (#590).
    local tasks="ansible/roles/ovos_hardware_mark1/tasks/config.yml"

    local overlay_line
    overlay_line="$(grep -n 'name: Manage TTY and soundcard overlays' "$tasks" | cut -d: -f1)"
    local serial_line
    serial_line="$(grep -n 'name: Assert the Mark 1 serial device exists' "$tasks" | cut -d: -f1)"

    [ -n "$overlay_line" ]
    [ -n "$serial_line" ]
    [ "$serial_line" -gt "$overlay_line" ]

    # ... and it must not be back in the up-front list either.
    run grep -q 'ovos_hardware_mark1_serial_device' ansible/roles/ovos_hardware_mark1/defaults/main.yml
    assert_success
    run bash -c "sed -n '/^ovos_hardware_mark1_required_paths:/,/^[a-z]/p' ansible/roles/ovos_hardware_mark1/defaults/main.yml | grep -q 'ovos_hardware_mark1_serial_device'"
    assert_failure
}

@test "mark1_serial_failure_tells_the_user_to_reboot" {
    run grep -q 'reboot and' ansible/roles/ovos_hardware_mark1/tasks/config.yml
    assert_success
}

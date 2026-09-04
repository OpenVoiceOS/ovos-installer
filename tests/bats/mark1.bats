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

# Ask required_packages() what it would install on one distribution.
function packages_for() {
    DISTRO_NAME="$1"
    RASPBERRYPI_MODEL="Raspberry Pi 3 Model B Rev 1.2"
    local recorder="$BATS_TMPDIR/packages.$$"
    : >"$recorder"
    eval "
        function install_debian_packages() { printf '%s\n' \"\$@\" >'$recorder'; }
        function install_fedora_packages() { printf '%s\n' \"\$@\" >'$recorder'; }
        function install_rhel_packages() { printf '%s\n' \"\$@\" >'$recorder'; }
        function install_opensuse_packages() { printf '%s\n' \"\$@\" >'$recorder'; }
        function install_arch_packages() { printf '%s\n' \"\$@\" >'$recorder'; }
    "
    required_packages >/dev/null 2>&1
    cat "$recorder"
    rm -f "$recorder"
}

@test "mark1_avrdude_dependencies_use_debian_names" {
    # libgpiod3 avrdude needs libusb-0.1, which Debian 13 does not ship (#590).
    run packages_for debian
    assert_line "libusb-0.1-4"
    assert_line "libhidapi-libusb0"
    assert_line "i2c-tools"
}

@test "mark1_avrdude_dependencies_use_fedora_names" {
    run packages_for fedora
    assert_line "libusb-compat-0.1"
    assert_line "hidapi"
    refute_line "libusb-0.1-4"
}

@test "mark1_avrdude_dependencies_use_opensuse_names" {
    run packages_for opensuse-tumbleweed
    assert_line "libusb-0_1-4"
    refute_line "libusb-0.1-4"
}

@test "mark1_avrdude_dependencies_use_arch_names" {
    run packages_for arch
    assert_line "libusb-compat"
    refute_line "libusb-0.1-4"
}

@test "mark1_avrdude_dependencies_are_skipped_without_a_board" {
    DISTRO_NAME="debian"
    RASPBERRYPI_MODEL="N/A"
    local recorder="$BATS_TMPDIR/packages.none"
    : >"$recorder"
    eval "function install_debian_packages() { printf '%s\n' \"\$@\" >'$recorder'; }"
    required_packages >/dev/null 2>&1
    run cat "$recorder"
    # No board, so no board-specific packages at all.
    assert_output ""
    rm -f "$recorder"
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

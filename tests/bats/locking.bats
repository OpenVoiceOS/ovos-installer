#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh

    LOG_FILE="/tmp/ovos-installer-locking.log"
    OVOS_INSTALLER_LOCK_FILE="/tmp/ovos-installer.lock.bats"
    export LOG_FILE OVOS_INSTALLER_LOCK_FILE
    : >"$LOG_FILE"
}

@test "function_acquire_installer_lock_and_release" {
    acquire_installer_lock
    assert_equal "$?" "0"

    run test -f "$OVOS_INSTALLER_LOCK_FILE"
    assert_success

    release_installer_lock
    run test -z "${OVOS_INSTALLER_LOCK_FD:-}"
    assert_success
}

@test "function_acquire_installer_lock_fails_when_already_held" {
    if ! command -v flock >/dev/null 2>&1; then
        skip "flock is required for lock contention test"
    fi

    bash -c 'exec 9>"$1"; flock -n 9; sleep 5' _ "$OVOS_INSTALLER_LOCK_FILE" &
    local locker_pid=$!
    sleep 0.3

    run acquire_installer_lock
    assert_failure
    assert_output --partial "Another OVOS installer process is already running"

    kill "$locker_pid" >/dev/null 2>&1 || true
    wait "$locker_pid" >/dev/null 2>&1 || true
}

@test "function_cleanup_installer_runtime_removes_temp_file_and_unlocks" {
    if ! command -v flock >/dev/null 2>&1; then
        skip "flock is required for unlock verification"
    fi

    acquire_installer_lock
    assert_equal "$?" "0"

    ha_extra_vars_file="$(mktemp /tmp/ovos-ha-extra-vars.XXXXXX)"
    export ha_extra_vars_file
    run test -f "$ha_extra_vars_file"
    assert_success

    cleanup_installer_runtime

    run test -f "$ha_extra_vars_file"
    assert_failure

    run bash -c 'exec 9>"$1"; flock -n 9' _ "$OVOS_INSTALLER_LOCK_FILE"
    assert_success
}

@test "function_exit_with_signal_code_uses_expected_exit_status" {
    ha_extra_vars_file="$(mktemp /tmp/ovos-ha-extra-vars.XXXXXX)"
    export ha_extra_vars_file

    run exit_with_signal_code 130
    assert_failure
    assert_equal "$status" "130"

    run test -f "$ha_extra_vars_file"
    assert_failure
}

function teardown() {
    release_installer_lock
    rm -f "$OVOS_INSTALLER_LOCK_FILE" "$LOG_FILE"
    if [ -n "${ha_extra_vars_file:-}" ]; then
        rm -f "$ha_extra_vars_file"
        unset ha_extra_vars_file
    fi
}

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
    local lock_rc=$?
    assert_equal "$lock_rc" "0"

    if command -v flock >/dev/null 2>&1; then
        run test -f "$OVOS_INSTALLER_LOCK_FILE"
        assert_success
    else
        run test -d "${OVOS_INSTALLER_LOCK_FILE}.d"
        assert_success
    fi

    release_installer_lock
    run test -z "${OVOS_INSTALLER_LOCK_FD:-}"
    assert_success
}

@test "function_acquire_installer_lock_fails_when_already_held" {
    if ! command -v flock >/dev/null 2>&1; then
        skip "flock is required for lock contention test"
    fi

    local lock_ready_file="${OVOS_INSTALLER_LOCK_FILE}.ready"
    rm -f "$lock_ready_file"

    bash -c 'exec 9>"$1"; flock -n 9 || exit 1; : >"$2"; sleep 5' _ "$OVOS_INSTALLER_LOCK_FILE" "$lock_ready_file" &
    local locker_pid=$!
    local lock_ready="false"
    local _attempt
    for _attempt in {1..30}; do
        if [ -f "$lock_ready_file" ]; then
            lock_ready="true"
            break
        fi
        if ! kill -0 "$locker_pid" 2>/dev/null; then
            break
        fi
        sleep 0.1
    done
    [ "$lock_ready" = "true" ]

    run acquire_installer_lock
    assert_failure
    assert_output --partial "Another OVOS installer process is already running"

    kill "$locker_pid" >/dev/null 2>&1 || true
    wait "$locker_pid" >/dev/null 2>&1 || true
    rm -f "$lock_ready_file"
}

@test "function_cleanup_installer_runtime_removes_temp_file_and_unlocks" {
    if ! command -v flock >/dev/null 2>&1; then
        skip "flock is required for unlock verification"
    fi

    acquire_installer_lock
    local lock_rc=$?
    assert_equal "$lock_rc" "0"

    ha_extra_vars_file="$(mktemp /tmp/ovos-ha-extra-vars.XXXXXX)"
    export ha_extra_vars_file
    run test -f "$ha_extra_vars_file"
    assert_success

    OVOS_INSTALLER_PIP_CONFIG_FILE="$(mktemp /tmp/ovos-pip-config.XXXXXX)"
    PIP_CONFIG_FILE="$OVOS_INSTALLER_PIP_CONFIG_FILE"
    export OVOS_INSTALLER_PIP_CONFIG_FILE PIP_CONFIG_FILE
    run test -f "$OVOS_INSTALLER_PIP_CONFIG_FILE"
    assert_success
    local pip_config_file="$OVOS_INSTALLER_PIP_CONFIG_FILE"

    cleanup_installer_runtime

    run test -f "$ha_extra_vars_file"
    assert_failure

    run test -f "$pip_config_file"
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
    if [ -n "${OVOS_INSTALLER_PIP_CONFIG_FILE:-}" ]; then
        rm -f "$OVOS_INSTALLER_PIP_CONFIG_FILE"
        unset OVOS_INSTALLER_PIP_CONFIG_FILE
    fi
    unset PIP_CONFIG_FILE
}

#!/usr/bin/env bats
#
# ovos-gui-watchdog: ovos-shell keeps memory it never gives back (#646), so the GUI
# installs run this beside it to kill the shell once it holds too much, and let the
# GUI unit's Restart=on-failure start a fresh one.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    WATCHDOG="$BATS_TEST_DIRNAME/../../ansible/roles/ovos_services/files/ovos-gui-watchdog.sh"
    FAKE="$(mktemp -d)"
    mkdir -p "$FAKE/bin" "$FAKE/proc"
    printf 'MemTotal:        1890304 kB\n' >"$FAKE/proc/meminfo"

    # The "shell" is a real process, so the kill and its signal are real too.
    sleep 300 &
    SHELL_PID=$!
    mkdir -p "$FAKE/proc/$SHELL_PID"

    # systemctl answers the unit's main PID, and records how it was asked.
    cat >"$FAKE/bin/systemctl" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$FAKE/systemctl.calls"
printf '%s\n' "\${FAKE_MAIN_PID:-$SHELL_PID}"
EOF
    chmod +x "$FAKE/bin/systemctl"
}

function teardown() {
    kill -KILL "$SHELL_PID" 2>/dev/null || true
    wait "$SHELL_PID" 2>/dev/null || true
    rm -rf "$FAKE"
}

# RSS and swap of the "shell", in kB.
function shell_uses() {
    printf 'Name:\tovos-shell\nVmRSS:\t%s kB\nVmSwap:\t%s kB\n' "$1" "$2" >"$FAKE/proc/$SHELL_PID/status"
}

function run_watchdog() {
    run env PATH="$FAKE/bin:$PATH" OVOS_GUI_WATCHDOG_PROC="$FAKE/proc" OVOS_GUI_WATCHDOG_ONCE=1 \
        bash "$WATCHDOG" "$@"
}

function shell_alive() {
    kill -0 "$SHELL_PID" 2>/dev/null
}

@test "gui watchdog: a shell under its limit is left alone" {
    shell_uses 300000 100000
    run_watchdog 512 ovos-gui.service --user
    assert_success
    assert_output ""
    shell_alive
}

@test "gui watchdog: RAM and swap together count against the limit" {
    # 300 MB resident and 250 MB paged out: each half alone is under 512 MB.
    shell_uses 307200 256000
    run_watchdog 512 ovos-gui.service --user
    assert_success
    assert_output --partial "pid ${SHELL_PID} holds 550 MB of RAM and swap, over its 512 MB limit"
    run bash -c "sleep 1; kill -0 $SHELL_PID"
    assert_failure
}

@test "gui watchdog: the shell is killed with SIGKILL, which systemd restarts" {
    # SIGTERM would count as a clean stop for Restart=on-failure and leave the
    # screen empty, so the signal matters as much as the kill.
    shell_uses 900000 0
    run_watchdog 512 ovos-gui.service --user
    assert_success
    local status=0
    wait "$SHELL_PID" || status=$?
    assert_equal "$status" "$((128 + 9))"
}

@test "gui watchdog: a share of the RAM is read from /proc/meminfo" {
    # 30% of 1846 MB, the Mark II, is 553 MB.
    shell_uses 540000 0
    run_watchdog '30%' ovos-gui.service --user
    assert_success
    assert_output ""
    shell_alive

    shell_uses 580000 0
    run_watchdog '30%' ovos-gui.service --user
    assert_output --partial "over its 553 MB limit"
}

@test "gui watchdog: it asks the unit's own scope for the main PID" {
    shell_uses 1000 0
    run_watchdog 512 ovos-gui.service --system
    assert_success
    run cat "$FAKE/systemctl.calls"
    assert_output "--system show --property MainPID --value ovos-gui.service"
}

@test "gui watchdog: a stopped GUI is not an error" {
    FAKE_MAIN_PID=0 run_watchdog 512 ovos-gui.service --user
    assert_success
    assert_output ""
    shell_alive
}

@test "gui watchdog: a limit it cannot use stops it instead of killing the shell" {
    # Read as zero, these would kill the shell every minute; "30 MB" would make
    # the arithmetic fail and the watchdog never act.
    shell_uses 900000 0
    local limit
    for limit in 0 '0%' 'abc%' '30 MB' '101%' '50%%' '-5' '' '1234567890'; do
        run_watchdog "$limit" ovos-gui.service --user
        assert_equal "$status" 2
        assert_output --partial "is not a usable limit"
        shell_alive
    done
}

@test "gui watchdog: a share of the RAM goes from 1% to 100%, and megabytes from 1" {
    shell_uses 1000 0
    local limit
    for limit in '1%' '100%' 1 '007'; do
        run_watchdog "$limit" ovos-gui.service --user
        assert_success
        shell_alive
    done
}

@test "gui watchdog: without a readable MemTotal a share cannot be worked out" {
    rm "$FAKE/proc/meminfo"
    shell_uses 900000 0
    run_watchdog '30%' ovos-gui.service --user
    assert_equal "$status" 2
    shell_alive
}

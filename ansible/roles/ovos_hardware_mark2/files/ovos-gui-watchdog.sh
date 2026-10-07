#!/usr/bin/env bash
# Keep ovos-shell from taking the device down with it.
#
# ovos-shell, the Qt 5 GUI of the Mark II and the DevKit, keeps memory it never
# gives back: a weather page costs tens of megabytes, other answers one or two, and
# it does not shrink when idle. The code is archived, so nothing upstream will
# change that (ovos-installer#646). Left alone it fills RAM and zram until the
# voice services crawl and it dies of SIGSEGV. A Raspberry Pi boots with
# cgroup_disable=memory, so systemd's MemoryMax= cannot cap it either.
#
# Every minute this reads the GUI unit's main process from /proc and, once it holds
# more than the limit in RAM and swap, kills it with SIGKILL. That counts as a
# failure for the unit's Restart=on-failure, so systemd starts a fresh shell;
# SIGTERM would count as a clean stop and leave the screen empty.
#
#   ovos-gui-watchdog <limit> [unit] [--user|--system]
#     limit   a whole number of megabytes, or a share of the RAM from 1% to 100%
#
# A limit that is anything else stops the watchdog with exit status 2 (which the
# unit does not restart): read as zero it would kill the shell every minute, and
# unreadable it would never act.
#
# OVOS_GUI_WATCHDOG_INTERVAL (seconds, 60), OVOS_GUI_WATCHDOG_ONCE (check once and
# exit) and OVOS_GUI_WATCHDOG_PROC (/proc) are there for the tests.
set -u

limit="${1?usage: ovos-gui-watchdog <limit in MB, or N%> [unit] [--user|--system]}"
unit="${2:-ovos-gui.service}"
scope="${3:---user}"
interval="${OVOS_GUI_WATCHDOG_INTERVAL:-60}"
proc="${OVOS_GUI_WATCHDOG_PROC:-/proc}"

# The limit in kB: megabytes as given, or the share of MemTotal. Empty when the
# limit is malformed, out of range, or the RAM cannot be read.
limit_kb() {
    local amount="${limit%\%}"
    case "$amount" in
    "" | *[!0-9]*) return 0 ;;
    esac
    # At most 9 digits, so the arithmetic below cannot overflow.
    if [ "${#amount}" -gt 9 ] || [ "$((10#$amount))" -le 0 ]; then
        return 0
    fi
    if [ "$amount" = "$limit" ]; then
        echo $((10#$amount * 1024))
    elif [ "$((10#$amount))" -le 100 ]; then
        awk -v share="$((10#$amount))" \
            '/^MemTotal:/ && $2 > 0 { printf "%d\n", $2 * share / 100 }' "$proc/meminfo" 2>/dev/null
    fi
}

max_kb="$(limit_kb)"
if [ -z "$max_kb" ] || [ "$max_kb" -le 0 ]; then
    echo "ovos-gui-watchdog: '${limit}' is not a usable limit: give a whole number of" \
        "megabytes, or a share of the RAM from 1% to 100%" >&2
    exit 2
fi

# Kill the unit's main process once it holds more than max_kb in RAM and swap.
check() {
    local pid used_kb
    pid="$(systemctl "$scope" show --property MainPID --value "$unit" 2>/dev/null || true)"
    case "$pid" in
    "" | 0) return 0 ;;
    esac
    [ -r "$proc/$pid/status" ] || return 0
    used_kb="$(awk '/^VmRSS:/ { r = $2 } /^VmSwap:/ { s = $2 } END { print r + s }' "$proc/$pid/status")"
    if [ "$used_kb" -gt "$max_kb" ]; then
        echo "${unit}: pid ${pid} holds $((used_kb / 1024)) MB of RAM and swap, over its" \
            "$((max_kb / 1024)) MB limit; killing it so systemd starts a fresh one"
        kill -KILL "$pid" 2>/dev/null || true
    fi
}

while true; do
    check
    if [ -n "${OVOS_GUI_WATCHDOG_ONCE:-}" ]; then
        exit 0
    fi
    sleep "$interval"
done

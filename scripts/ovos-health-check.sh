#!/usr/bin/env bash
# OVOS Installer Health Check & Validation Script
#
# Tests 9 categories: PR fix validation, system info, Docker status,
# systemd services, installation directories, audio, messagebus,
# network/DNS, and resource usage.
#
# Usage:
#   bash scripts/ovos-health-check.sh
#   bash scripts/ovos-health-check.sh 2>&1 | tee /tmp/ovos-health-report.txt
#
# Runs without root for most checks; auto-elevates via sudo where needed.
set -o pipefail

PASS=0
FAIL=0
INFO=0
RESULTS=()

# Print a section header with underline decoration
print_header() {
    echo ""
    echo "========================================"
    echo "  $1"
    echo "========================================"
}

# Record and print a passing check, increment PASS counter
pass() {
    PASS=$((PASS + 1))
    RESULTS+=("PASS|$1")
    echo "  [PASS] $1"
}

# Record and print a failing check, increment FAIL counter
fail() {
    FAIL=$((FAIL + 1))
    RESULTS+=("FAIL|$1")
    echo "  [FAIL] $1"
}

# Record and print an informational note, increment INFO counter
info() {
    INFO=$((INFO + 1))
    RESULTS+=("INFO|$1")
    echo "  [INFO] $1"
}

# Detect if running inside the ovos-installer repo
REPO_ROOT=""
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
for candidate in "$SCRIPT_DIR/.." "$SCRIPT_DIR/../.." "$PWD" "/tmp/ovos-installer"; do
    candidate="$(cd "$candidate" 2>/dev/null && pwd)"
    if [ -f "$candidate/ansible/site.yml" ] && [ -d "$candidate/.git" ]; then
        REPO_ROOT="$candidate"
        break
    fi
done

# ===========================================
print_header "1/9: PR #541 Fix Validation"
# ===========================================
echo "  (Checking that the Reload Systemd User handler fix is in place)"

HANDLERS="$REPO_ROOT/ansible/roles/ovos_services/handlers/main.yml"
RUNTIME="$REPO_ROOT/ansible/roles/ovos_services/tasks/systemd-user-runtime.yml"

if [ -z "$REPO_ROOT" ]; then
    info "ovos-installer repo not found (deleted after successful install) - skipping PR fix validation"
    info "Run this script from within the cloned repo to validate the PR fix"
elif [ -f "$HANDLERS" ] && [ -f "$RUNTIME" ]; then
    awk "/^- name: Reload Systemd User$/,/^$/" "$HANDLERS" | grep -q "failed_when: false" \
        && pass "Handler: failed_when: false present" \
        || fail "Handler: failed_when: false MISSING"

    awk "/^- name: Reload Systemd User$/,/^$/" "$HANDLERS" | grep -q "ovos_installer_systemd_scope" \
        && pass "Handler: systemd_scope guard present" \
        || fail "Handler: systemd_scope guard MISSING"

    awk "/^- name: Reload Systemd User$/,/^$/" "$HANDLERS" | grep -q "ovos_services_user_systemd_available" \
        && pass "Handler (Reload Systemd User): user_systemd_available guard present" \
        || fail "Handler (Reload Systemd User): user_systemd_available guard MISSING"

    awk "/^- name: Restart OVOS services \(user\)$/,/^$/" "$HANDLERS" | grep -q "ovos_services_user_systemd_available" \
        && pass "Handler (Restart OVOS services user): user_systemd_available guard present" \
        || fail "Handler (Restart OVOS services user): user_systemd_available guard MISSING"

    awk "/^- name: Restart WirePlumber$/,/^$/" "$HANDLERS" | grep -q "ovos_services_user_systemd_available" \
        && pass "Handler (Restart WirePlumber): user_systemd_available guard present" \
        || fail "Handler (Restart WirePlumber): user_systemd_available guard MISSING"

    awk "/^- name: Restart PipeWire$/,/^$/" "$HANDLERS" | grep -q "ovos_services_user_systemd_available" \
        && pass "Handler (Restart PipeWire): user_systemd_available guard present" \
        || fail "Handler (Restart PipeWire): user_systemd_available guard MISSING"

    grep -q "Probe user systemd availability" "$RUNTIME" \
        && pass "Runtime: Probe task present" \
        || fail "Runtime: Probe task MISSING"

    grep -q "ovos_services_user_systemd_available" "$RUNTIME" \
        && pass "Runtime: Fact set for availability" \
        || fail "Runtime: Fact set MISSING"

    awk "/^- name: Ensure user systemd instance is running$/,/^$/" "$RUNTIME" | grep -q "failed_when: false" \
        && pass "Runtime: Ensure instance has failed_when: false" \
        || fail "Runtime: Ensure instance MISSING failed_when: false"
else
    info "Repo found at $REPO_ROOT but handler/runtime files missing (unexpected state)"
fi

# ===========================================
print_header "2/9: System Info"
# ===========================================

echo "  Hostname: $(hostname 2>/dev/null || echo 'unknown')"
echo "  Kernel:   $(uname -r 2>/dev/null || echo 'unknown')"
echo "  Arch:     $(uname -m 2>/dev/null || echo 'unknown')"
echo "  Date:     $(date -u '+%Y-%m-%d %H:%M:%S UTC')"
echo "  User:     $(whoami 2>/dev/null || echo 'unknown')"

if [ -f /etc/os-release ]; then
    . /etc/os-release
    echo "  OS:       $NAME $VERSION"
fi

# Detect if running on Raspberry Pi
PI_MODEL=""
if [ -f /proc/device-tree/model ]; then
    PI_MODEL=$(tr -d '\0' </proc/device-tree/model 2>/dev/null || true)
fi
if [ -n "$PI_MODEL" ]; then
    echo "  Pi Model: $PI_MODEL"
fi

MEM_TOTAL=$(grep MemTotal /proc/meminfo 2>/dev/null | awk '{print $2}')
if [ -n "$MEM_TOTAL" ]; then
    echo "  Memory:   $((MEM_TOTAL / 1024)) MB"
fi

# ===========================================
print_header "3/9: Docker Status"
# ===========================================

if command -v docker &>/dev/null; then
    docker info &>/dev/null && pass "Docker daemon is running" || fail "Docker daemon is NOT running"

    CONTAINERS=$(docker ps --format '{{.Names}}' 2>/dev/null || true)
    if [ -n "$CONTAINERS" ]; then
        pass "Running containers detected"
        while IFS= read -r c; do echo "    - $c"; done <<< "$CONTAINERS"
    else
        ALL_CONTAINERS=$(docker ps -a --format '{{.Names}}' 2>/dev/null || true)
        if [ -n "$ALL_CONTAINERS" ]; then
            info "Containers exist but none are running"
            while IFS= read -r c; do echo "    - $c"; done <<< "$ALL_CONTAINERS"
        else
            info "No Docker containers found"
        fi
    fi

    COMPOSE_DIRS=()
    for d in /tmp/ovos-docker ~/ovos-docker /home/*/ovos-docker; do
        [ -d "$d/compose" ] && COMPOSE_DIRS+=("$d")
    done
    if [ ${#COMPOSE_DIRS[@]} -gt 0 ]; then
        pass "ovos-docker compose directory found"
        for d in "${COMPOSE_DIRS[@]}"; do echo "    - $d"; done
    else
        info "No ovos-docker compose directory found (may be in a custom path)"
    fi
else
    info "Docker not installed on this system"
fi

# Determine the real user (not root) for user-level checks
if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    REAL_USER="$SUDO_USER"
elif [ "$(id -u)" -eq 0 ] && [ -z "${SUDO_USER:-}" ]; then
    REAL_USER="$(logname 2>/dev/null || echo 'root')"
else
    REAL_USER="$USER"
fi

# Run systemctl --user as the real user (works even when script runs as root).
# Sets XDG_RUNTIME_DIR and DBUS_SESSION_BUS_ADDRESS for the target user.
systemctl_user() {
    if [ "$(id -u)" -eq 0 ]; then
        sudo -u "$REAL_USER" XDG_RUNTIME_DIR="/run/user/$(id -u "$REAL_USER")" \
            DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$REAL_USER")/bus" \
            systemctl --user "$@" 2>/dev/null
    else
        systemctl --user "$@" 2>/dev/null
    fi
}

print_header "4/9: Systemd Service Status"
# ===========================================

if command -v systemctl &>/dev/null; then
    pass "systemctl is available"

    # Check user-level systemd (the fix target)
    if systemctl_user show-environment &>/dev/null; then
        pass "User systemd instance is available ($REAL_USER)"
    else
        info "User systemd instance NOT available (expected on headless root, fix handles this)"
    fi

    # Check key OVOS services (user scope, managed by docker-compose)
    for svc in ovos.service ovos-messagebus.service; do
        if systemctl_user is-enabled "$svc" &>/dev/null; then
            pass "systemd user: $svc is enabled"
            systemctl_user is-active "$svc" &>/dev/null \
                && pass "systemd user: $svc is active" \
                || fail "systemd user: $svc is NOT active"
        else
            info "systemd user: $svc not found (expected for container-based install)"
        fi
    done

    # Check PHAL admin (system scope)
    SUDO_CTL=""
    [ "$(id -u)" -ne 0 ] && SUDO_CTL="sudo"
    if $SUDO_CTL systemctl is-enabled ovos-phal-admin.service &>/dev/null 2>&1; then
        pass "systemd system: ovos-phal-admin.service is enabled"
        $SUDO_CTL systemctl is-active ovos-phal-admin.service &>/dev/null 2>&1 \
            && pass "systemd system: ovos-phal-admin.service is active" \
            || fail "systemd system: ovos-phal-admin.service is NOT active"
    else
        info "systemd system: ovos-phal-admin.service not found (expected on some profiles)"
    fi
else
    info "systemctl not available on this system"
fi

# ===========================================
print_header "5/9: OVOS Installation Directories"
# ===========================================

OVOS_HOME="$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6 || echo "/home/$REAL_USER")"

if [ -n "$OVOS_HOME" ]; then
    for dir in \
        "$OVOS_HOME/ovos/config" \
        "$OVOS_HOME/ovos/config/phal" \
        "$OVOS_HOME/ovos/config/persona" \
        "$OVOS_HOME/ovos/share" \
        "$OVOS_HOME/.config/systemd/user"; do
        if [ -d "$dir" ]; then
            pass "Directory exists: $dir"
        else
            info "Directory not found: $dir (expected for some profiles)"
        fi
    done

    if [ -d "$OVOS_HOME/.venvs/ovos" ]; then
        pass "Virtualenv found at $OVOS_HOME/.venvs/ovos"
    elif [ -d "$OVOS_HOME/ovos" ]; then
        info "No virtualenv found (container-based install uses Docker)"
    else
        info "No OVOS installation directory found at $OVOS_HOME"
    fi
fi

# ===========================================
print_header "6/9: Audio System"
# ===========================================

if command -v pactl &>/dev/null; then
    pactl info &>/dev/null && pass "PipeWire/PulseAudio is running" || info "PipeWire/PulseAudio not running"
    SINKS=$(pactl list sinks short 2>/dev/null | wc -l)
    SOURCES=$(pactl list sources short 2>/dev/null | wc -l)
    echo "    Sinks: $SINKS, Sources: $SOURCES"
elif command -v aplay &>/dev/null; then
    aplay -l 2>/dev/null | grep -q "^card" \
        && pass "ALSA playback devices detected" \
        || info "No ALSA playback devices"
fi

if command -v wpctl &>/dev/null; then
    wpctl status 2>/dev/null | head -5
fi

# ===========================================
print_header "7/9: OVOS Messagebus Connectivity"
# ===========================================

MESSAGEBUS_PORT=0
for port in 6715 5678 8888; do
    if ss -tlnp 2>/dev/null | grep -q ":$port "; then
        MESSAGEBUS_PORT=$port
        pass "OVOS Messagebus listening on port $port"
        break
    fi
done
if [ "$MESSAGEBUS_PORT" -eq 0 ]; then
    # Also check for OVOS messagebus unix socket
    for sock in /tmp/ovos-messagebus.sock; do
        if [ -S "$sock" ] 2>/dev/null; then
            pass "OVOS Messagebus socket found: $sock"
            MESSAGEBUS_PORT=-1
            break
        fi
    done
fi
if [ "$MESSAGEBUS_PORT" -eq 0 ]; then
    info "No OVOS Messagebus port or socket detected"
fi

# ===========================================
print_header "8/9: Network & DNS"
# ===========================================

# Resolve a hostname using host, getent, or ping (fallback chain).
# Returns 0 if reachable, 1 if all methods fail.
resolve_host() {
    host "$1" &>/dev/null && return 0
    getent hosts "$1" &>/dev/null && return 0
    ping -c1 -W1 "$1" &>/dev/null && return 0
    return 1
}
for host in github.com api.openvoiceos.com; do
    resolve_host "$host" && pass "Network reachable: $host" || info "Network: $host not reachable (expected on some networks)"
done

# Check if OVOS ports are accessible
for port in 80 443; do
    ss -tlnp 2>/dev/null | grep -q ":$port " && info "Port $port is listening" || true
done

# ===========================================
print_header "9/9: Resources & Logs"
# ===========================================

# Disk usage
DISK_USE=$(df -h / | awk 'NR==2{print $5}')
echo "  Root disk usage: $DISK_USE"

MEM_AVAIL=$(grep MemAvailable /proc/meminfo 2>/dev/null | awk '{print $2}')
if [ -n "$MEM_AVAIL" ]; then
    echo "  Available memory: $((MEM_AVAIL / 1024)) MB"
fi

LOAD=$(uptime | awk -F'load average:' '{print $2}')
echo "  Load average: $LOAD"

# Check recent OVOS logs
LOG_DIRS=(
    "/var/log/syslog"
    "$OVOS_HOME/.local/state/mycroft"
    "$OVOS_HOME/ovos/tmp"
)
for log in "${LOG_DIRS[@]}"; do
    if [ -f "$log" ]; then
        ERRORS=$(grep -ci "error\|fail\|traceback" "$log" 2>/dev/null || echo 0)
        [ "$ERRORS" -gt 20 ] && info "$log: $ERRORS recent errors (may be normal)" || true
        break
    elif [ -d "$log" ]; then
        echo "  Log dir: $log"
        ls "$log" 2>/dev/null | head -5
        break
    fi
done

# ===========================================
print_header "SUMMARY"
# ===========================================
echo ""
printf "  %-10s %3d\n" "PASS:" $PASS
printf "  %-10s %3d\n" "FAIL:" $FAIL
printf "  %-10s %3d\n" "INFO:" $INFO
echo ""

if [ "$FAIL" -eq 0 ]; then
    echo "  ALL CHECKS PASSED"
else
    echo "  $FAIL CHECK(S) FAILED - review details above"
    echo ""
    echo "  Failed checks:"
    for r in "${RESULTS[@]}"; do
        IFS='|' read -r status name <<< "$r"
        [ "$status" = "FAIL" ] && echo "    - $name"
    done
fi

echo ""
echo "  Log this output with:"
echo "    bash scripts/ovos-health-check.sh 2>&1 | tee /tmp/ovos-health-report.txt"
echo ""

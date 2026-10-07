#!/usr/bin/env bash
# Prove that an uninstall gives the machine back the way the install found it.
#
#   machine_state.sh snapshot <dir>   before the install: record everything the
#                                     installer can touch
#   machine_state.sh compare <dir>    after the uninstall: record it again and fail on
#                                     anything the install left behind, or anything
#                                     that was there before and is gone now
#
# A list of paths to check for would only ever cover what someone thought of. A
# before/after comparison also catches what nobody did: a new file the install
# writes and the uninstall forgets, a package it installs and leaves, a volume the
# cleanup skips because of its name, or a package the uninstall removes that was
# never the installer's.
#
# Recorded, per kind:
#   home        the install user's home, four levels down
#   system      the system paths the roles write: units, wrappers, drop-ins,
#               lingering, /opt, and root's home (setup.sh runs as root)
#   packages    the distribution's package list (dpkg, pacman or Homebrew)
#   docker      containers, volumes, networks and images
#   groups      the groups the install user is in
#   services    loaded OVOS and HiveMind units or launchd jobs
#
# Some differences are intended, or are the CI's own doing, and are listed in
# machine_state.allow next to this script with the reason for each. After the
# uninstall, nothing of OVOS may still be running or listening either.
#
# Run it as the install user, not under sudo: HOME decides whose home is compared.
# It uses sudo itself for what only root can read.
set -euo pipefail

mode="${1:-}"
dir="${2:-}"
if [ -z "$mode" ] || [ -z "$dir" ]; then
    echo "usage: $0 snapshot|compare <dir>" >&2
    exit 2
fi
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
allow_file="${MACHINE_STATE_ALLOW:-${here}/machine_state.allow}"

# The CI restores these from its own cache before the install, so they are there
# "before" for reasons that have nothing to do with the installer: the
# installer's uv cache, pip and uv caches, Ansible's collections, the checkout.
home_prunes=(
    "${HOME}/.ovos-installer"
    "${HOME}/.cache/pip"
    "${HOME}/.cache/uv"
    "${HOME}/.ansible"
    "${HOME}/Library/Caches"
    "${GITHUB_WORKSPACE:-${HOME}/work}"
    "${HOME}/work"
    "${RUNNER_TEMP:-/nonexistent}"
)

system_paths=(
    /etc/systemd/system
    /etc/systemd/user
    /etc/systemd/zram-generator.conf
    /usr/local/bin
    /usr/local/sbin
    /etc/security/limits.d
    /etc/NetworkManager/conf.d
    /etc/NetworkManager/dnsmasq.d
    /etc/udev/rules.d
    /etc/tmpfiles.d
    /etc/modprobe.d
    /etc/modules-load.d
    /etc/sudoers.d
    /etc/apt/sources.list.d
    /etc/yum.repos.d
    /var/lib/systemd/linger
    /var/lib/ovos-installer
    /opt
    /root
    /Library/LaunchDaemons
    /Library/LaunchAgents
)

record_home() {
    local prune=()
    local path
    for path in "${home_prunes[@]}"; do
        prune+=(-path "$path" -prune -o)
    done
    find "$HOME" -mindepth 1 -maxdepth 4 "${prune[@]}" -print 2>/dev/null | LC_ALL=C sort
}

record_system() {
    local path depth
    for path in "${system_paths[@]}"; do
        if sudo -n test -e "$path" 2>/dev/null; then
            # Two levels of /opt: deeper is Homebrew's and the runner's tool cache,
            # which change on their own. Homebrew's packages are compared as packages.
            depth=3
            [ "$path" = /opt ] && depth=2
            # /root is the one entry here under a home of its own, with the same
            # caches as the user's.
            sudo -n find "$path" -maxdepth "$depth" \
                \( -path /root/.cache/pip -o -path /root/.cache/uv -o -path /root/.ansible \) -prune \
                -o -print 2>/dev/null || true
        fi
    done | LC_ALL=C sort -u
}

record_packages() {
    if command -v dpkg-query >/dev/null 2>&1; then
        dpkg-query -W -f '${db:Status-Abbrev} ${Package}\n' 2>/dev/null | awk '$1 ~ /^ii/ {print $2}'
    elif command -v rpm >/dev/null 2>&1; then
        rpm -qa --qf '%{NAME}\n'
    elif command -v pacman >/dev/null 2>&1; then
        pacman -Qq
    elif command -v brew >/dev/null 2>&1; then
        brew list --formula -1 2>/dev/null
        brew list --cask -1 2>/dev/null | sed 's/^/cask:/'
    fi | LC_ALL=C sort -u
}

docker_cli() {
    if docker info >/dev/null 2>&1; then
        docker "$@"
    elif sudo -n docker info >/dev/null 2>&1; then
        sudo -n docker "$@"
    else
        return 1
    fi
}

record_docker() {
    command -v docker >/dev/null 2>&1 || return 0
    {
        docker_cli ps -a --format 'container:{{.Names}}' || true
        docker_cli volume ls --format 'volume:{{.Name}}' || true
        docker_cli network ls --format 'network:{{.Name}}' || true
        docker_cli images --format 'image:{{.Repository}}:{{.Tag}}' || true
    } 2>/dev/null | LC_ALL=C sort -u
}

record_groups() {
    id -nG "$(id -un)" | tr ' ' '\n' | LC_ALL=C sort -u
}

record_services() {
    if command -v systemctl >/dev/null 2>&1; then
        systemctl list-units --all --plain --no-legend 'ovos*' 'hivemind*' 2>/dev/null | awk '{print "system:" $1}'
        systemctl --user list-units --all --plain --no-legend 'ovos*' 'hivemind*' 2>/dev/null | awk '{print "user:" $1}'
    fi
    if command -v launchctl >/dev/null 2>&1; then
        launchctl list 2>/dev/null | awk '$3 ~ /ovos|hivemind|mycroft/ {print "launchd:" $3}'
    fi
}

snapshot() {
    local out="$1"
    mkdir -p "$out"
    record_home >"$out/home"
    record_system >"$out/system"
    record_packages >"$out/packages"
    record_docker >"$out/docker"
    record_groups >"$out/groups"
    record_services | LC_ALL=C sort -u >"$out/services"
}

# The allow list: "<kind> <added|removed> <extended regex>", one per line, with the
# reason in a comment above it. $HOME stands for the install user's home.
allowed() {
    local kind="$1" change="$2" entry="$3"
    local k c pattern
    [ -f "$allow_file" ] || return 1
    while read -r k c pattern; do
        case "$k" in "" | \#*) continue ;; esac
        [ "$k" = "$kind" ] && [ "$c" = "$change" ] || continue
        pattern="${pattern//\$HOME/$HOME}"
        if [[ "$entry" =~ ^${pattern}$ ]]; then
            return 0
        fi
    done <"$allow_file"
    return 1
}

compare() {
    local before="$1"
    local after kind
    # A missing snapshot compares as empty against empty, and would pass.
    for kind in home system packages docker groups services; do
        if [ ! -f "$before/$kind" ]; then
            echo "no snapshot of '${kind}' in ${before}: record one before the install" >&2
            return 2
        fi
    done
    after="$(mktemp -d)"
    trap 'rm -rf "$after"' RETURN
    snapshot "$after"

    local failed=0 change entry
    for kind in home system packages docker groups services; do
        for change in added removed; do
            local -a found=()
            if [ "$change" = "added" ]; then
                mapfile -t found < <(LC_ALL=C comm -13 "$before/$kind" "$after/$kind")
            else
                mapfile -t found < <(LC_ALL=C comm -23 "$before/$kind" "$after/$kind")
            fi
            for entry in "${found[@]}"; do
                [ -n "$entry" ] || continue
                if allowed "$kind" "$change" "$entry"; then
                    echo "  allowed  ${kind} ${change}: ${entry}"
                    continue
                fi
                if [ "$change" = "added" ]; then
                    echo "LEFT BEHIND ${kind}: ${entry}"
                else
                    echo "GONE       ${kind}: ${entry} (it was there before the install)"
                fi
                failed=1
            done
        done
    done

    # Whatever the files say, nothing of OVOS may still run or listen.
    # ps rather than pgrep: pgrep's flags mean different things on Linux and macOS.
    local running
    # shellcheck disable=SC2009
    running="$(ps -axo pid=,command= 2>/dev/null |
        grep -E -- '\.venvs/ovos/|ovos-core|ovos-audio|ovos-dinkum-listener|ovos-messagebus|ovos-phal|ovos_PHAL|ovos-gui|hivemind-core|hivemind-listener|hivemind-voice-sat' |
        grep -v -E -- 'grep|machine_state' || true)"
    if [ -n "$running" ]; then
        echo "STILL RUNNING:"
        printf '  %s\n' "$running"
        failed=1
    fi
    local port
    for port in 8181 5678 18181; do
        if (command -v ss >/dev/null 2>&1 && ss -ltnH "sport = :${port}" 2>/dev/null | grep -q .) ||
            (! command -v ss >/dev/null 2>&1 && command -v lsof >/dev/null 2>&1 &&
                lsof -nP -iTCP:"${port}" -sTCP:LISTEN >/dev/null 2>&1); then
            echo "STILL LISTENING on ${port}"
            failed=1
        fi
    done

    if [ "$failed" -ne 0 ]; then
        echo "the uninstall did not give the machine back the way the install found it" >&2
        return 1
    fi
    echo "the uninstall gave the machine back the way the install found it"
}

case "$mode" in
snapshot) snapshot "$dir" ;;
compare) compare "$dir" ;;
*)
    echo "usage: $0 snapshot|compare <dir>" >&2
    exit 2
    ;;
esac

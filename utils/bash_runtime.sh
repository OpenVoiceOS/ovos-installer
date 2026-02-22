#!/usr/bin/env sh

# Return the current operating system identifier.
#
# Returns:
#   - System name from uname (e.g. Linux, Darwin), or "unknown" if unavailable.
bash_runtime_detect_system() {
    uname -s 2>/dev/null || echo unknown
}

# Print candidate Bash paths for macOS hosts.
#
# Returns:
#   - One candidate path per line.
bash_runtime_macos_candidates() {
    printf '%s\n' /opt/homebrew/bin/bash /usr/local/bin/bash
}

# Read Bash major version for an executable candidate.
#
# Args:
#   - $1: Bash executable path
#
# Returns:
#   - Prints detected major version number (0 when undetectable)
#   - Exit code 0 when input path exists and is executable, 1 otherwise.
bash_runtime_major_version() {
    _ovos_bash_candidate="${1:-}"
    _ovos_bash_major="0"

    if [ -z "$_ovos_bash_candidate" ] || [ ! -x "$_ovos_bash_candidate" ]; then
        printf '%s\n' "$_ovos_bash_major"
        return 1
    fi

    _ovos_bash_major="$("$_ovos_bash_candidate" -c "printf '%s' \"\${BASH_VERSINFO[0]:-0}\"" 2>/dev/null || printf '0')"
    case "$_ovos_bash_major" in
        '' | *[!0-9]*) _ovos_bash_major="0" ;;
    esac
    printf '%s\n' "$_ovos_bash_major"
    return 0
}

# Resolve a compatible Bash runtime path.
#
# This helper prefers Homebrew Bash locations on macOS and falls back to
# the first Bash binary from PATH. A compatible runtime is Bash major
# version 4 or newer by default.
#
# Args:
#   - $1: Minimum supported Bash major version (default: 4)
#
# Returns:
#   - 0 and prints the Bash executable path when found
#   - 1 when no compatible Bash runtime is available
resolve_bash_runtime() {
    _ovos_min_bash_major="${1:-4}"
    _ovos_system_name="$(bash_runtime_detect_system)"
    _ovos_candidate=""
    _ovos_candidate_major="0"

    case "$_ovos_min_bash_major" in
        '' | *[!0-9]*) _ovos_min_bash_major="4" ;;
    esac

    if [ "$_ovos_system_name" = "Darwin" ]; then
        for _ovos_candidate in $(bash_runtime_macos_candidates); do
            _ovos_candidate_major="$(bash_runtime_major_version "$_ovos_candidate")"
            if [ "$_ovos_candidate_major" -ge "$_ovos_min_bash_major" ]; then
                printf '%s\n' "$_ovos_candidate"
                return 0
            fi
        done
    fi

    if command -v bash >/dev/null 2>&1; then
        _ovos_candidate="$(command -v bash)"
        _ovos_candidate_major="$(bash_runtime_major_version "$_ovos_candidate")"
        if [ "$_ovos_candidate_major" -ge "$_ovos_min_bash_major" ]; then
            printf '%s\n' "$_ovos_candidate"
            return 0
        fi
    fi

    return 1
}

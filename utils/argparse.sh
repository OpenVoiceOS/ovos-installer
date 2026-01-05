#!/usr/bin/env bash
set -euo pipefail

# Usage instruction for available arguments
function usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help          Display this help message"
    echo "  -d, --debug         Enable debug mode for more verbosity"
    echo "  -u, --uninstall     Uninstall Open Voice OS instance"
    echo
}

# Parse command line arguments, handling both short and long options
# We are not using getopts as it only handles short arguments
# such as -v where this method handles short and long arguments
# such as --verbose
function handle_options() {
    while [ $# -gt 0 ]; do
        case $1 in
        -d | --debug)
            export DEBUG="true"
            ;;
        -u | --uninstall)
            export CONFIRM_UNINSTALL_CLI="true"
            ;;
        -h | --help)
            usage
            exit 0
            ;;
        *)
            echo "Invalid option: $1" >&2
            usage
            exit 1
            ;;
        esac
        shift
    done

    # To reduce UX clutter, the following options are not exposed as CLI flags,
    # instead the user can specify them via environment variables.

    # If USE_UV is true, install and use uv instead of pip, which can be
    # significantly faster.
    export USE_UV="${USE_UV:-true}"

    # If REUSE_CACHED_ARTIFACTS is true, keep any existing ansible venv which
    # speeds up the installer, but could result in errors if it is in a dirty
    # state. This is mainly useful when debugging the installer.
    export REUSE_CACHED_ARTIFACTS="${REUSE_CACHED_ARTIFACTS:-false}"

    # Set default values for variables that may not be set
    export DEBUG="${DEBUG:-false}"
    export METHOD="${METHOD:-virtualenv}"
    export PROFILE="${PROFILE:-ovos}"
    export CHANNEL="${CHANNEL:-stable}"
    export TUNING="${TUNING:-no}"
    export SHARE_TELEMETRY="${SHARE_TELEMETRY:-false}"
    export SHARE_USAGE_TELEMETRY="${SHARE_USAGE_TELEMETRY:-false}"
    export FEATURE_SKILLS="${FEATURE_SKILLS:-true}"
    export FEATURE_EXTRA_SKILLS="${FEATURE_EXTRA_SKILLS:-false}"
    export FEATURE_GUI="${FEATURE_GUI:-false}"
    export OVOS_VENV_PYTHON="${OVOS_VENV_PYTHON:-3.11}"
    export HIVEMIND_HOST="${HIVEMIND_HOST:-}"
    export HIVEMIND_PORT="${HIVEMIND_PORT:-}"
    export SATELLITE_KEY="${SATELLITE_KEY:-}"
    export SATELLITE_PASSWORD="${SATELLITE_PASSWORD:-}"
    export UNINSTALL="${UNINSTALL:-false}"
    export CONFIRM_UNINSTALL="${CONFIRM_UNINSTALL:-false}"
    export CONFIRM_UNINSTALL_CLI="${CONFIRM_UNINSTALL_CLI:-false}"
    export INSTALLER_VERSION="${INSTALLER_VERSION:-unknown}"
}

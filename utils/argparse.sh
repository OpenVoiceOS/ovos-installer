#!/usr/bin/env bash

# Usage instruction for available arguments
function usage() {
    echo "Usage: $0 [OPTIONS]"
    echo "Options:"
    echo "  -h, --help          Display this help message"
    echo "  -d, --debug         Enable debug mode for more verbosity"
    echo "  -u, --uninstall     Uninstall Open Voice OS instance"
    echo
}

# Parse the arguments passed to the command line.
# We are not using getopts as it only handles short arguments
# such as -v where this method handle short and long arguments
# such as --verbode
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
}


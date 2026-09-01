#!/usr/bin/env bash
# Stand in for the detect_* stages of setup.sh so the TUI can be walked on its
# own, with only what a plain machine exports before tui/main.sh runs.
cd "${REPO_ROOT:?}" || exit 1

# shellcheck source=utils/constants.sh
source utils/constants.sh
# setup.sh turns errexit off for the TUI.
set +eo pipefail

export LOCALE="${LOCALE:-en-us}"
LOG_FILE="$(mktemp)"
INSTALLER_STATE_FILE="$(mktemp)"
rm -f "$INSTALLER_STATE_FILE"
RUN_AS_HOME="$(mktemp -d)"
export LOG_FILE INSTALLER_STATE_FILE RUN_AS_HOME

export EXISTING_INSTANCE="${EXISTING_INSTANCE:-false}"
export ARCH="x86_64"
export DISTRO_NAME="ubuntu"
export DISTRO_VERSION="Ubuntu 24.04"
export DISTRO_VERSION_ID="24"
export DISTRO_LABEL="Ubuntu 24.04"
export KERNEL="6.8.0"
export PYTHON="Python 3.12.3"
export CPU_IS_CAPABLE="true"
export SOUND_SERVER="PipeWire"
export DISPLAY_SERVER="wayland"
export VENV_PATH="${RUN_AS_HOME}/.venvs/ovos"
export RASPBERRYPI_MODEL="N/A"
export HARDWARE_MODEL="N/A"
declare -a DETECTED_DEVICES=()
export DETECTED_DEVICES

# shellcheck source=tui/main.sh
source tui/main.sh

printf 'REACHED_END method=%s channel=%s profile=%s\n' "${METHOD:-}" "${CHANNEL:-}" "${PROFILE:-}"

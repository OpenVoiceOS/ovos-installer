#!/usr/bin/env bash
# The finish screen runs after the playbook, so it is reached on its own.
cd "${REPO_ROOT:?}" || exit 1

# shellcheck source=utils/constants.sh
source utils/constants.sh
set +eo pipefail

# setup.sh overrides the locale for the duration of the install; the wrapping
# the dialogs measure depends on it, so mirror that here.
if locale -a 2>/dev/null | grep -qiE '^c\.utf-?8$'; then
  export LANG=C.UTF-8 LC_ALL=C.UTF-8
elif locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
  export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
fi

export LOCALE="en-us"
# A plausible path: this ends up in the screenshot.
export RUN_AS_HOME="/home/user"
export LOG_FILE="/dev/null"
export METHOD="virtualenv"
export RASPBERRYPI_MODEL="N/A"
export TUNING="no"
export FEATURE_GUI="false"

# shellcheck source=tui/finish.sh
source tui/finish.sh

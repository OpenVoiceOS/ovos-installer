#!/usr/bin/env bash
# Run the intent round trip with whichever interpreter can already reach the bus.
#
# A virtualenv install has websocket-client in its venv, because ovos-bus-client depends
# on it - so use that python and install nothing. A containers install has no host venv,
# so fall back to the system python and add the one dependency. Either way the bus is on
# 127.0.0.1:8181: ovos-docker publishes the messagebus with network_mode: host.
#
# Never run this under sudo. HOME decides which mycroft.conf is read, and the deployment
# belongs to the install user, not to root.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
venv_python="${OVOS_VENV_PYTHON:-${HOME}/.venvs/ovos/bin/python}"

if [ -x "${venv_python}" ] && "${venv_python}" -c "import websocket" 2>/dev/null; then
    echo "using the installed venv interpreter: ${venv_python}"
    exec "${venv_python}" "${here}/assert_intent_roundtrip.py" "$@"
fi

python_bin="${PYTHON_BIN:-python3}"
if ! "${python_bin}" -c "import websocket" 2>/dev/null; then
    echo "installing websocket-client for ${python_bin}"
    "${python_bin}" -m pip install --quiet --disable-pip-version-check websocket-client \
        || "${python_bin}" -m pip install --quiet --disable-pip-version-check --break-system-packages websocket-client
fi
exec "${python_bin}" "${here}/assert_intent_roundtrip.py" "$@"

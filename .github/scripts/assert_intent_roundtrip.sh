#!/usr/bin/env bash
# Run the intent round trip with whichever interpreter can already reach the bus.
#
# A virtualenv install has websocket-client in its venv, because ovos-bus-client depends
# on it - so use that python and install nothing. A containers install has no host venv,
# so the one dependency goes into a throwaway directory on PYTHONPATH. It must not go to
# ~/.local: the installer runs under sudo and leaves root-owned paths there, so a plain
# `pip install` fails with EACCES on a runner. Nothing here needs root, and nothing here
# should write outside the temporary directory it makes.
#
# Never run this under sudo. HOME decides which mycroft.conf is read, and the deployment
# belongs to the install user rather than to root.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
venv_python="${OVOS_VENV_PYTHON:-${HOME}/.venvs/ovos/bin/python}"

if [ -x "${venv_python}" ] && "${venv_python}" -c "import websocket" 2>/dev/null; then
    echo "using the deployment's own interpreter: ${venv_python}"
    exec "${venv_python}" "${here}/assert_intent_roundtrip.py" "$@"
fi

python_bin="${PYTHON_BIN:-python3}"
if "${python_bin}" -c "import websocket" 2>/dev/null; then
    exec "${python_bin}" "${here}/assert_intent_roundtrip.py" "$@"
fi

target="$(mktemp -d)"
trap 'rm -rf "${target}"' EXIT
echo "installing websocket-client into ${target}"
if ! "${python_bin}" -m pip install --quiet --disable-pip-version-check \
        --target "${target}" websocket-client; then
    echo "could not install websocket-client, so the bus cannot be reached from here" >&2
    exit 1
fi
PYTHONPATH="${target}${PYTHONPATH:+:${PYTHONPATH}}" \
    exec "${python_bin}" "${here}/assert_intent_roundtrip.py" "$@"

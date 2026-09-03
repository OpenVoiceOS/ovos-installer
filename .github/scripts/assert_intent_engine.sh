#!/usr/bin/env bash
# Assert the virtualenv ended up with a padatious intent engine, and that the
# fann2 build chain matches the padatious it actually got.
#
# padatious reaches the venv only through an ovos-core extra - no requirements
# template asks for it by name - and which extra carries it changed between the
# 1.x and 2.x lines. That makes it quietly droppable: an install can succeed,
# report failed=0, and have no intent engine at all. This is the check that
# says so out loud.
#
# The fann2 half is derived from the installed padatious rather than from the
# channel, so it keeps holding once stable and testing move to a 2.x core.

set -euo pipefail

python_bin="${1:?usage: assert_intent_engine.sh <venv-python> [run-as-user]}"
run_as="${2:-}"

assertion=$(
    cat <<'PY'
from importlib.metadata import PackageNotFoundError, version


def installed(name):
    try:
        return version(name)
    except PackageNotFoundError:
        return None


padatious = installed("ovos-padatious")
if padatious is None:
    raise SystemExit(
        "no intent engine: ovos-padatious is not installed. It reaches the venv "
        "only through an ovos-core extra, so an extra was changed without an "
        "explicit replacement requirement."
    )

fann2 = installed("fann2")
needs_fann2 = int(padatious.split(".")[0]) < 2

if needs_fann2 and fann2 is None:
    raise SystemExit(
        f"ovos-padatious {padatious} is a 1.x release and needs fann2, "
        "but fann2 is not installed - the build chain was skipped where it "
        "was still required."
    )

if not needs_fann2 and fann2 is not None:
    # Not fatal: a reused venv can still carry it from an earlier install.
    print(
        f"note: ovos-padatious {padatious} does not need fann2, "
        f"yet fann2 {fann2} is present"
    )

print(f"intent engine ok: ovos-padatious {padatious}, fann2 {fann2 or 'not needed'}")
PY
)

if [ ! -x "${python_bin}" ]; then
    echo "no virtualenv python at ${python_bin}" >&2
    exit 1
fi

if [ -n "${run_as}" ]; then
    sudo -u "${run_as}" "${python_bin}" -c "${assertion}"
else
    "${python_bin}" -c "${assertion}"
fi

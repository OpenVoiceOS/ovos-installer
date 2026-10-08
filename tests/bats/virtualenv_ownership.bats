#!/usr/bin/env bats
#
# Whatever in the OVOS virtualenv is not the user's is found and handed back before
# uv installs as the user: root's bytecode, left by the PHAL admin service, once
# stopped a Mark II install when uv could not replace numpy. The two tasks are taken
# from venv.yml as they are and run under ansible-playbook, in check mode, where
# handing a file to another user would need root.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    if ! command -v ansible-playbook >/dev/null 2>&1; then
        skip "ansible-playbook is not available"
    fi

    T="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/ownership.XXXXXX")"
    mkdir -p "$T/venv/lib/numpy/__pycache__"
    : >"$T/venv/lib/numpy/__pycache__/core.cpython-311.pyc"
    python3 - "$PWD/ansible/roles/ovos_virtualenv/tasks/venv.yml" "$T/tasks.yml" <<'PY'
import sys, yaml
wanted = ("Look for anything in the OVOS virtualenv that is not the user's",
          "Ensure OVOS virtualenv ownership is aligned before package installs")
tasks = [t for t in yaml.safe_load(open(sys.argv[1])) if t.get("name") in wanted]
assert [t["name"] for t in tasks] == list(wanted), [t["name"] for t in tasks]
yaml.safe_dump(tasks, open(sys.argv[2], "w"), sort_keys=False)
PY
    cat >"$T/play.yml" <<YAML
- hosts: localhost
  gather_facts: false
  tasks:
    - ansible.builtin.import_tasks: $T/tasks.yml
YAML
}

function teardown() {
    [ -n "${T:-}" ] && rm -rf "$T"
}

# play <user the virtualenv belongs to> <their group>
function play() {
    run ansible-playbook -i localhost, -c local --check "$T/play.yml" -e "{
        \"ovos_virtualenv_path\": \"$T/venv\", \"ovos_virtualenv_is_cleaning\": false,
        \"ovos_virtualenv_repair_ownership\": false, \"ovos_virtualenv_venv_create\": {\"changed\": false},
        \"ovos_installer_user\": \"$1\", \"ovos_installer_group\": \"$2\"
    }"
    assert_success
}

# What became of the ownership task: changed, ok or skipping.
function ownership_result() {
    awk '/^TASK \[Ensure OVOS virtualenv ownership is aligned/ { on = 1; next }
         on && /^(changed|ok|skipping):/ { sub(/:.*/, ""); print; exit }' <<<"$output"
}

@test "virtualenv ownership: a virtualenv that is all the user's is left alone" {
    play "$(id -un)" "$(id -gn)"
    [ "$(ownership_result)" = skipping ]
}

@test "virtualenv ownership: bytecode another account wrote is handed back to the user" {
    # The test's own files are not root's, as root's bytecode is not the user's.
    play root "$(id -gn root 2>/dev/null || echo root)"
    [ "$(ownership_result)" = changed ]
}

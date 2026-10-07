#!/usr/bin/env bats
#
# The uninstall removes the OVOS virtualenv and nothing else in ~/.venvs: a user's
# own virtualenvs live there too. It used to skip the OVOS virtualenv whenever
# Ansible ran from anywhere in ~/.venvs, which the installer always does, and leave
# setup.sh to remove ~/.venvs whole. Run for real under ansible-playbook against a
# scratch home.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    if ! command -v ansible-playbook >/dev/null 2>&1; then
        skip "ansible-playbook is not available"
    fi

    T="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/venvs.XXXXXX")"
    H="$T/home"
    mkdir -p "$H/.venvs/ovos/bin" "$H/.venvs/ovos-installer/bin" "$H/.venvs/their-project/bin"
    : >"$H/.venvs/ovos/bin/python"
    : >"$H/.venvs/ovos-installer/bin/python"
    echo "home = /usr/bin" >"$H/.venvs/their-project/pyvenv.cfg"

    cat >"$T/play.yml" <<'YAML'
- hosts: localhost
  gather_facts: false
  tasks:
    - ansible.builtin.include_role:
        name: ovos_virtualenv
        tasks_from: uninstall_virtualenv.yml
YAML
}

function teardown() {
    [ -n "${T:-}" ] && rm -rf "$T"
}

# play [more ansible-playbook arguments]
function play() {
    run ansible-playbook -i localhost, -c local "$T/play.yml" \
        -e "ovos_installer_user_home=$H" \
        -e "ovos_virtualenv_uninstall_python=$H/.venvs/ovos-installer/bin/python" "$@"
    assert_success
}

@test "virtualenv uninstall: the OVOS virtualenv goes, the installer's and the user's stay" {
    play
    [ ! -e "$H/.venvs/ovos" ]
    [ -f "$H/.venvs/ovos-installer/bin/python" ]
    [ -f "$H/.venvs/their-project/pyvenv.cfg" ]
}

@test "virtualenv uninstall: never the virtualenv the uninstall runs from, unless forced" {
    play -e "ovos_virtualenv_uninstall_python=$H/.venvs/ovos/bin/python"
    assert_output --partial "this uninstall runs from it"
    [ -f "$H/.venvs/ovos/bin/python" ]

    play -e "ovos_virtualenv_uninstall_python=$H/.venvs/ovos/bin/python" -e ovos_virtualenv_force_remove=true
    [ ! -e "$H/.venvs/ovos" ]
    [ -f "$H/.venvs/their-project/pyvenv.cfg" ]
}

@test "virtualenv uninstall: a virtualenv whose name only starts the same is not the OVOS one" {
    # ~/.venvs/ovos-installer starts with ~/.venvs/ovos: running from it is not
    # running from the OVOS virtualenv.
    play -e "ovos_virtualenv_uninstall_python=$H/.venvs/ovos-installer/bin/python"
    [ ! -e "$H/.venvs/ovos" ]
}

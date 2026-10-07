#!/usr/bin/env bats
#
# The installer's uv goes in ~/.local/bin unless the user already had one there. Run
# for real under ansible-playbook against a scratch home.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    if ! command -v ansible-playbook >/dev/null 2>&1; then
        skip "ansible-playbook is not available"
    fi

    T="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/uv.XXXXXX")"
    H="$T/home"
    mkdir -p "$H/.venvs/ovos-installer/bin" "$H/.cache/ovos-installer/package-tracking"
    echo "the installer's uv" >"$H/.venvs/ovos-installer/bin/uv"
    # ovos_virtualenv runs inside ovos_installer, whose defaults name the record.
    cat >"$T/play.yml" <<YAML
- hosts: localhost
  gather_facts: false
  vars_files:
    - $PWD/ansible/roles/ovos_installer/defaults/main.yml
  tasks:
    - ansible.builtin.include_role:
        name: ovos_virtualenv
        tasks_from: user_uv.yml
YAML
}

function teardown() {
    [ -n "${T:-}" ] && rm -rf "$T"
}

function play() {
    run ansible-playbook -i localhost, -c local "$T/play.yml" -e "{
        \"ansible_become\": false,
        \"ovos_installer_user\": \"$(id -un)\",
        \"ovos_installer_group\": \"$(id -gn)\",
        \"ovos_installer_user_home\": \"$H\",
        \"ovos_installer_venv\": \"$H/.venvs/ovos-installer\"
    }"
    assert_success
}

# record <paths the first install found absent, as a JSON list>
function record() {
    printf '{"absent": %s, "orphans": []}\n' "$1" >"$H/.cache/ovos-installer/package-tracking/footprint.json"
}

@test "user uv: a uv the user had before the first install is left as it is" {
    mkdir -p "$H/.local/bin"
    echo "their uv" >"$H/.local/bin/uv"
    record '[]'

    play
    assert_output --partial "was there before"
    run cat "$H/.local/bin/uv"
    assert_output "their uv"
}

@test "user uv: where the first install found none, it gets the installer's" {
    record "[\"$H/.local/bin/uv\"]"

    play
    run cat "$H/.local/bin/uv"
    assert_output "the installer's uv"
}

@test "user uv: a record that is there but cannot be read leaves the uv as it is" {
    mkdir -p "$H/.local/bin"
    echo "their uv" >"$H/.local/bin/uv"
    # Unreadable for root too: a directory where the record's file should be.
    mkdir "$H/.cache/ovos-installer/package-tracking/footprint.json"

    play
    assert_output --partial "could not be read"
    run cat "$H/.local/bin/uv"
    assert_output "their uv"
}

@test "user uv: an install from before the record keeps getting the installer's" {
    mkdir -p "$H/.local/bin"
    echo "an older copy" >"$H/.local/bin/uv"

    play
    run cat "$H/.local/bin/uv"
    assert_output "the installer's uv"
}

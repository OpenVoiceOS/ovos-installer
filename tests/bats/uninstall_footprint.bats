#!/usr/bin/env bats
#
# The first install records what of its side effects was not there yet - its own uv
# and Python, the models OVOS downloads, the sound stack's state, the directories on
# the way - and the uninstall removes exactly those. Run for real under
# ansible-playbook against a scratch home.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    if ! command -v ansible-playbook >/dev/null 2>&1; then
        skip "ansible-playbook is not available"
    fi

    T="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/footprint.XXXXXX")"
    H="$T/home"
    mkdir -p "$H"
    ME="$(id -un)"

    cat >"$T/record.yml" <<'YAML'
- hosts: localhost
  gather_facts: true
  gather_subset: [min]
  tasks:
    - ansible.builtin.include_role:
        name: ovos_installer
        tasks_from: footprint_record.yml
YAML
    # Read, then what the uninstall's directory removal does in between, then restore.
    cat >"$T/restore.yml" <<'YAML'
- hosts: localhost
  gather_facts: true
  gather_subset: [min]
  tasks:
    - ansible.builtin.include_role:
        name: ovos_installer
        tasks_from: footprint_read.yml
    - ansible.builtin.file:
        path: "{{ ovos_installer_user_home }}/.cache/ovos-installer"
        state: absent
    - ansible.builtin.include_role:
        name: ovos_installer
        tasks_from: footprint_restore.yml
YAML
}

function teardown() {
    [ -n "${T:-}" ] && rm -rf "$T"
}

function play() {
    run ansible-playbook -i localhost, -c local "$T/$1.yml" -e "{
        \"ansible_become\": false,
        \"ovos_installer_user\": \"$ME\",
        \"ovos_installer_user_home\": \"$H\",
        \"ovos_installer_venv_python\": \"3.11\",
        \"ovos_installer_footprint_owner\": \"$ME\"
    }"
    assert_success
}

# What an install leaves in a home: its uv and Python, an OVOS model, the sound
# stack's state, a user unit directory.
function install_side_effects() {
    mkdir -p "$H/.local/bin" "$H/.local/share/uv/python/cpython-3.11" "$H/.local/state/wireplumber" \
        "$H/.config/pulse" "$H/.config/systemd/user" \
        "$H/.cache/huggingface/hub/models--OpenVoiceOS--ovos-m2v-intents-multilingual/snapshots"
    local file
    for file in .local/bin/uv .local/bin/python3.11 .config/pulse/cookie .local/state/wireplumber/default-nodes; do
        [ -e "$H/$file" ] || : >"$H/$file"
    done
}

@test "footprint: a home the install found empty is given back empty" {
    play record
    install_side_effects
    # macOS: the installer's lines in ~/.zshrc are already gone, the file stays empty.
    : >"$H/.zshrc"

    play restore
    run find "$H" -mindepth 1
    assert_output ""
}

@test "footprint: what the user had before the install stays, the install's own goes" {
    mkdir -p "$H/.local/bin" "$H/.config" "$H/.cache/huggingface/hub/models--someone--their-model"
    echo "their uv" >"$H/.local/bin/uv"
    echo 'export EDITOR=vim' >"$H/.zshrc"
    play record
    install_side_effects

    play restore
    # Theirs.
    run cat "$H/.local/bin/uv"
    assert_output "their uv"
    run cat "$H/.zshrc"
    assert_output "export EDITOR=vim"
    [ -d "$H/.cache/huggingface/hub/models--someone--their-model" ]
    # The install's: gone, even inside a cache that was already there.
    [ ! -e "$H/.cache/huggingface/hub/models--OpenVoiceOS--ovos-m2v-intents-multilingual" ]
    [ ! -e "$H/.local/share/uv" ]
    [ ! -e "$H/.local/bin/python3.11" ]
    [ ! -e "$H/.local/state" ]
    [ ! -e "$H/.config/systemd" ]
    [ -d "$H/.config" ]
}

@test "footprint: a file the install created keeps whatever was added to it since" {
    play record
    echo 'alias ll="ls -l"' >"$H/.zshrc"

    play restore
    run cat "$H/.zshrc"
    assert_output 'alias ll="ls -l"'
}

@test "footprint: a record that names other paths cannot make the uninstall remove them" {
    play record
    mkdir -p "$H/precious"
    echo keep >"$H/precious/file"
    local record="$H/.cache/ovos-installer/package-tracking/footprint.json"
    printf '{"absent": ["%s/precious", "%s/precious/file", "%s"], "orphans": null}\n' "$H" "$H" "$H" >"$record"

    play restore
    run cat "$H/precious/file"
    assert_output "keep"
}

@test "footprint: an install from before the record exists removes none of it" {
    install_side_effects

    play restore
    # No record: nothing of the footprint is guessed at, except OVOS's own models.
    [ -e "$H/.local/bin/uv" ]
    [ -e "$H/.local/share/uv" ]
    [ ! -e "$H/.cache/huggingface/hub/models--OpenVoiceOS--ovos-m2v-intents-multilingual" ]
}

@test "sound groups: the record holds the sound groups the user is a member of, and only those" {
    cat >"$T/groups.yml" <<YAML
- hosts: localhost
  gather_facts: false
  tasks:
    - ansible.builtin.debug:
        msg: "GROUPS={{ lookup('ansible.builtin.template', '$PWD/ansible/roles/ovos_sound/templates/sound_groups_member.j2') | trim }}"
YAML
    # getent's shape: name -> [password, gid, comma-separated members].
    run ansible-playbook -i localhost, -c local "$T/groups.yml" -e '{
        "ovos_installer_user": "pi",
        "ovos_sound_audio_group": "audio", "ovos_sound_rtkit_group": "rtkit", "ovos_sound_pipewire_group": "pipewire",
        "ovos_sound_getent_group": {
            "audio": ["x", "29", "pulse,pi"],
            "rtkit": ["x", "120", ""],
            "pipewire": ["x", "121", "pipewire-user"],
            "video": ["x", "44", "pi"]
        }
    }'
    assert_success
    assert_output --partial 'GROUPS=["audio"]'
}

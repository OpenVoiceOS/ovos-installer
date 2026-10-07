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
  gather_facts: false
  tasks:
    - ansible.builtin.include_role:
        name: ovos_installer
        tasks_from: footprint_record.yml
YAML
    # No facts: these tasks need none, and gathering them costs over a minute a play on
    # the macOS runners, which pushed the suite past its time limit there.
    # Read, then what the uninstall's directory removal does in between, then restore.
    cat >"$T/restore.yml" <<'YAML'
- hosts: localhost
  gather_facts: false
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

# play <record|restore> [more ansible-playbook arguments]
function play() {
    local book="$1"
    shift
    run ansible-playbook -i localhost, -c local "$T/${book}.yml" -e "{
        \"ansible_become\": false,
        \"ovos_installer_user\": \"$ME\",
        \"ovos_installer_user_home\": \"$H\",
        \"ovos_installer_venv_python\": \"3.11\",
        \"ovos_installer_footprint_owner\": \"$ME\"
    }" "$@"
    assert_success
}

# What an install leaves in a home: its uv and Python, an OVOS model, onnxruntime's
# device id and database, the sound stack's state, a user unit directory. uv's
# Python is a link into uv's own tree.
function install_side_effects() {
    mkdir -p "$H/.local/bin" "$H/.local/share/uv/python/cpython-3.11/bin" "$H/.local/state/wireplumber" \
        "$H/.config/pulse" "$H/.config/systemd/user" \
        "$H/.cache/huggingface/hub/models--OpenVoiceOS--ovos-m2v-intents-multilingual/snapshots" \
        "$H/.cache/Microsoft/DeveloperTools/.onnxruntime"
    local file
    for file in .local/bin/uv .local/share/uv/python/cpython-3.11/bin/python3.11 .config/pulse/cookie \
        .local/state/wireplumber/default-nodes .cache/Microsoft/DeveloperTools/.onnxruntime/onnxruntime.db; do
        [ -e "$H/$file" ] || : >"$H/$file"
    done
    [ -e "$H/.local/bin/python3.11" ] ||
        ln -s "$H/.local/share/uv/python/cpython-3.11/bin/python3.11" "$H/.local/bin/python3.11"
}

# Gone, and not even a dangling link left in its place.
function gone() {
    [ ! -e "$1" ] && [ ! -L "$1" ]
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
    mkdir -p "$H/.local/bin" "$H/.config" "$H/.cache/huggingface/hub/models--someone--their-model" \
        "$H/.cache/Microsoft/DeveloperTools"
    echo "their uv" >"$H/.local/bin/uv"
    echo "their device" >"$H/.cache/Microsoft/DeveloperTools/deviceid"
    echo 'export EDITOR=vim' >"$H/.zshrc"
    play record
    install_side_effects

    play restore
    # Theirs: their own tool's device id stays, and the directories it sits in.
    run cat "$H/.local/bin/uv"
    assert_output "their uv"
    [ -f "$H/.cache/Microsoft/DeveloperTools/deviceid" ]
    gone "$H/.cache/Microsoft/DeveloperTools/.onnxruntime"
    run cat "$H/.zshrc"
    assert_output "export EDITOR=vim"
    [ -d "$H/.cache/huggingface/hub/models--someone--their-model" ]
    # The install's: gone, even inside a cache that was already there.
    gone "$H/.cache/huggingface/hub/models--OpenVoiceOS--ovos-m2v-intents-multilingual"
    gone "$H/.local/share/uv"
    gone "$H/.local/bin/python3.11"
    gone "$H/.local/state"
    gone "$H/.config/systemd"
    [ -d "$H/.config" ]
}

@test "footprint: recording leaves the permissions of an existing cache alone" {
    mkdir -p "$H/.cache"
    chmod 0700 "$H/.cache"
    play record
    # find rather than stat: stat's flags differ between Linux and macOS.
    run find "$H/.cache" -maxdepth 0 -perm 0700
    assert_output "$H/.cache"
    [ -f "$H/.cache/ovos-installer/package-tracking/footprint.json" ]
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

@test "footprint: nothing is removed or read through a symbolic link out of the home" {
    play record
    # ~/.local/share is a link to somewhere else entirely: its uv must not be reached.
    mkdir -p "$T/elsewhere/uv" "$H/.local"
    echo keep >"$T/elsewhere/uv/file"
    ln -s "$T/elsewhere" "$H/.local/share"
    # A ~/.zshrc that is a link is the user's, whatever it points to holds.
    : >"$T/elsewhere/zshrc"
    ln -s "$T/elsewhere/zshrc" "$H/.zshrc"

    play restore
    run cat "$T/elsewhere/uv/file"
    assert_output "keep"
    [ -L "$H/.local/share" ]
    [ -L "$H/.zshrc" ]
    [ -f "$T/elsewhere/zshrc" ]
}

@test "footprint: the directories setup.sh made for its state are the install's" {
    # setup.sh creates ~/.local/state/ovos before the playbook records anything.
    mkdir -p "$H/.local/state/ovos"
    play record -e "ovos_installer_state_created_from=$H/.local"
    install_side_effects
    # The uninstall's own directory removal takes the state directory.
    rm -rf "$H/.local/state/ovos"

    play restore
    run find "$H" -mindepth 1
    assert_output ""
}

@test "footprint: only setup.sh's state directory or one above it in the home is believed" {
    # The home would make everything configured count as the install's, and a
    # directory beside the state directory everything in it.
    local claimed
    for claimed in "$H" "$H/.config"; do
        rm -rf "$H"
        mkdir -p "$H/.local/state/ovos" "$H/.config/pulse"
        echo theirs >"$H/.config/pulse/client.conf"
        play record -e "ovos_installer_state_created_from=$claimed"
        rm -rf "$H/.local/state/ovos"

        play restore
        run cat "$H/.config/pulse/client.conf"
        assert_output "theirs"
        [ -d "$H/.local/state" ]
    done
}

@test "footprint: nothing the uninstall runs on is removed, and it says so" {
    play record
    install_side_effects
    # The uninstall's interpreter, reached through ~/.local/bin/python3.11 the way
    # an installer virtualenv built on uv's Python reaches it: the chain ends at the
    # Python Ansible itself runs on, and Ansible comes from its usual place.
    local playbook ansible_python site venv="$T/installer-venv"
    playbook="$(command -v ansible-playbook)"
    # --version names the interpreter; the shebang may be "/usr/bin/env python3".
    ansible_python="$(ansible-playbook --version </dev/null 2>/dev/null | sed -n 's/^ *python version = .*(\(\/[^)]*\))$/\1/p')"
    [ -x "$ansible_python" ]
    site="$("$ansible_python" -c 'import ansible, os; print(os.path.dirname(os.path.dirname(ansible.__file__)))')"
    mkdir -p "$venv/bin"
    ln -sf "$("$ansible_python" -c 'import os, sys; print(os.path.realpath(sys.executable))')" \
        "$H/.local/share/uv/python/cpython-3.11/bin/python3.11"
    ln -s "$H/.local/bin/python3.11" "$venv/bin/python"

    run env PYTHONPATH="$site" "$venv/bin/python" "$playbook" -i localhost, -c local "$T/restore.yml" -e "{
        \"ansible_become\": false,
        \"ovos_installer_user\": \"$ME\",
        \"ovos_installer_user_home\": \"$H\",
        \"ovos_installer_venv_python\": \"3.11\",
        \"ovos_installer_footprint_owner\": \"$ME\"
    }"
    assert_success
    assert_output --partial "Left in place, because this uninstall runs on it"
    [ -L "$H/.local/bin/python3.11" ]
    [ -e "$H/.local/share/uv/python/cpython-3.11/bin/python3.11" ]
    # Everything else still goes.
    gone "$H/.local/bin/uv"
    gone "$H/.config/pulse"
}

@test "footprint: a removal that fails is reported, and the uninstall goes on" {
    play record
    install_side_effects
    # A directory the uninstall cannot empty: its parent refuses the removal.
    chmod 0555 "$H/.config/pulse"

    play restore
    assert_output --partial "stays:"
    chmod 0755 "$H/.config/pulse"
}

@test "footprint: the record holds what the package manager already considered unneeded" {
    mkdir -p "$T/bin"
    printf '#!/usr/bin/env bash\n[ "$1" = "-Qtdq" ] && printf "%%s\\n" old-orphan other-orphan\n' >"$T/bin/pacman"
    chmod +x "$T/bin/pacman"
    PATH="$T/bin:$PATH" play record -e ovos_installer_package_family=Archlinux
    run python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["orphans"])' \
        "$H/.cache/ovos-installer/package-tracking/footprint.json"
    assert_output "['old-orphan', 'other-orphan']"
}

@test "footprint: a package manager that could not say is recorded as not knowing" {
    # An empty list would let the uninstall remove everything unneeded at the time.
    mkdir -p "$T/bin"
    printf '#!/usr/bin/env bash\nexit 9\n' >"$T/bin/pacman"
    chmod +x "$T/bin/pacman"
    PATH="$T/bin:$PATH" play record -e ovos_installer_package_family=Archlinux
    run python3 -c 'import json, sys; print("orphans" in json.load(open(sys.argv[1])))' \
        "$H/.cache/ovos-installer/package-tracking/footprint.json"
    assert_output "False"
}

@test "footprint: a record that holds no list of orphans is read as not knowing" {
    # Older records wrote "" where the package manager could not say.
    local record="$H/.cache/ovos-installer/package-tracking/footprint.json" orphans
    mkdir -p "$(dirname "$record")"
    cat >"$T/read.yml" <<'YAML'
- hosts: localhost
  gather_facts: false
  tasks:
    - ansible.builtin.include_role:
        name: ovos_installer
        tasks_from: footprint_read.yml
    - ansible.builtin.debug:
        msg: "KNOWN={{ ovos_installer_footprint.orphans is defined }} ABSENT={{ ovos_installer_footprint.absent | length }}"
YAML
    for orphans in '""' 'null' '{}' '"libfoo"'; do
        printf '{"absent": ["%s/.zshrc"], "orphans": %s}\n' "$H" "$orphans" >"$record"
        play read
        assert_output --partial "KNOWN=False ABSENT=1"
    done
    printf '{"absent": [], "orphans": ["libfoo"]}\n' >"$record"
    play read
    assert_output --partial "KNOWN=True"
}

#!/usr/bin/env bats
#
# Which Homebrew formulae are the install's, and how the uninstall gives them back.
# Run for real under ansible-playbook, against a brew that answers like Homebrew
# does and records how it was asked.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    if ! command -v ansible-playbook >/dev/null 2>&1; then
        skip "ansible-playbook is not available"
    fi

    T="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/brew.XXXXXX")"
    mkdir -p "$T/bin"
    cat >"$T/bin/brew" <<EOF
#!/usr/bin/env bash
printf '%s\n' "\$*" >>"$T/calls"
case "\$1 \$2 \$3" in
"info --json=v2 --formula") [ -f "$T/info-formula.json" ] && exec cat "$T/info-formula.json"; exit 1 ;;
"info --json=v2 --installed") exec cat "$T/info-installed.json" ;;
esac
case "\$1 \$2" in
"list --formula") exec cat "$T/list" ;;
"tab --no-installed-on-request") exit 0 ;;
esac
exit 1
EOF
    chmod +x "$T/bin/brew"
}

function teardown() {
    [ -n "${T:-}" ] && rm -rf "$T"
}

# formulae <name>... - the JSON brew info prints for these installed formulae
function formulae() {
    local name list=""
    for name in "$@"; do
        list="${list:+$list,}{\"name\":\"$name\",\"installed\":[{\"version\":\"1\"}]}"
    done
    printf '{"formulae":[%s],"casks":[]}\n' "$list"
}

# play <tasks file> <extra vars as JSON>
function play() {
    cat >"$T/play.yml" <<YAML
- hosts: localhost
  gather_facts: true
  gather_subset: [min]
  tasks:
    - ansible.builtin.include_role:
        name: ovos_installer
        tasks_from: $1
    - ansible.builtin.debug:
        msg: "TRACKED={{ ovos_installer_package_tracking_tracked_packages | default([]) | to_json }}"
YAML
    run ansible-playbook -i localhost, -c local "$T/play.yml" -e '{"ansible_become": false, "ovos_installer_user": "'"$(id -un)"'"}' -e "$2"
    assert_success
}

@test "homebrew: a formula the machine had under another name is not the install's" {
    # pkg-config is pkgconf and icu4c is icu4c@78, both already installed: only mpv
    # and sox are new.
    formulae pkgconf icu4c@78 mpv sox >"$T/info-formula.json"
    printf '%s\n' pkgconf icu4c@78 node@24 >"$T/list"
    play package_tracking_prepare_macos.yml '{
        "ovos_installer_package_tracking_marker_path": "'"$T"'/marker.json",
        "ovos_installer_package_tracking_requested_packages": ["pkg-config", "icu4c", "mpv", "sox"],
        "ovos_installer_package_tracking_homebrew_path": "'"$T"'/bin"
    }'
    assert_output --partial 'TRACKED=["mpv", "sox"]'
}

@test "homebrew: the uninstall hands the install's formulae to autoremove, aliases from old records left out" {
    # A record from before Homebrew's own names holds icu4c, which is icu4c@78 and
    # was the machine's; ffmpeg came in as a dependency and is not in the record.
    formulae icu4c@78 ffmpeg flac mpv sox >"$T/info-installed.json"
    play package_tracking_release_macos.yml '{
        "ovos_installer_package_tracking_tracked_packages_to_remove": ["flac", "icu4c", "mpv", "sox", "uninstalled-since"],
        "ovos_installer_package_tracking_homebrew_path": "'"$T"'/bin"
    }'
    run cat "$T/calls"
    assert_output "info --json=v2 --installed
tab --no-installed-on-request flac mpv sox"
}

@test "homebrew: nothing to give back asks brew nothing more" {
    formulae icu4c@78 >"$T/info-installed.json"
    play package_tracking_release_macos.yml '{
        "ovos_installer_package_tracking_tracked_packages_to_remove": ["icu4c"],
        "ovos_installer_package_tracking_homebrew_path": "'"$T"'/bin"
    }'
    run grep -c "^tab " "$T/calls"
    assert_output "0"
}

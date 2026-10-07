#!/usr/bin/env bats
#
# unneeded_packages.sh: what dnf, zypper and pacman consider unneeded, and an
# uninstall that removes only what became unneeded since the install. Run against
# package managers that answer like the real ones and remember what they were told.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    SCRIPT="$BATS_TEST_DIRNAME/../../ansible/roles/ovos_installer/files/unneeded_packages.sh"
    FAKE="$(mktemp -d)"
    mkdir -p "$FAKE/bin"
    # The installed packages nothing needs, one per line in $FAKE/unneeded. Removing
    # a name takes it out, and puts in what the removed package alone was holding:
    # $FAKE/holds/<name> lists those.
    mkdir -p "$FAKE/holds"
    for tool in dnf zypper pacman rpm; do
        cat >"$FAKE/bin/$tool" <<EOF
#!/usr/bin/env bash
printf '%s %s\n' "$tool" "\$*" >>"$FAKE/calls"
[ -f "$FAKE/fail" ] && exit 9
case "$tool \$1" in
"dnf repoquery") printf '%s\n\n' \$(cat "$FAKE/unneeded") ;;
"zypper --quiet")
    echo "S  | Repository | Name | Version | Arch"
    echo "---+------------+------+---------+-----"
    while read -r name; do echo "i  | @System    | \$name | 1.0 | x86_64"; done <"$FAKE/unneeded"
    ;;
"pacman -Qtdq") [ -s "$FAKE/unneeded" ] || exit 1; cat "$FAKE/unneeded" ;;
"rpm -e" | "zypper --non-interactive" | "pacman -R")
    for name in "\$@"; do
        case "\$name" in -*|remove) continue ;; esac
        grep -vx "\$name" "$FAKE/unneeded" >"$FAKE/unneeded.new" || true
        mv "$FAKE/unneeded.new" "$FAKE/unneeded"
        if [ -f "$FAKE/holds/\$name" ]; then cat "$FAKE/holds/\$name" >>"$FAKE/unneeded"; fi
    done
    ;;
esac
exit 0
EOF
        chmod +x "$FAKE/bin/$tool"
    done
    PATH="$FAKE/bin:$PATH"
}

function teardown() {
    rm -rf "$FAKE"
}

@test "unneeded packages: each package manager's list comes back as names" {
    printf '%s\n' libfoo libbar >"$FAKE/unneeded"
    local family
    for family in RedHat Suse Archlinux; do
        run bash "$SCRIPT" list "$family"
        assert_success
        assert_output "libbar
libfoo"
    done
}

@test "unneeded packages: pacman finding nothing is an empty list, not a failure" {
    : >"$FAKE/unneeded"
    run bash "$SCRIPT" list Archlinux
    assert_success
    assert_output ""
}

@test "unneeded packages: a list that could not be had is a failure, not an empty one" {
    printf '%s\n' libfoo >"$FAKE/unneeded"
    : >"$FAKE/fail"
    local family
    for family in RedHat Suse Archlinux; do
        run bash "$SCRIPT" list "$family"
        assert_failure
    done
}

@test "unneeded packages: the uninstall removes what became unneeded, a layer at a time, and keeps what was before" {
    # Before the install, old-orphan was already unneeded. The uninstall left
    # libsox unneeded, and libsox alone was holding libmad.
    printf '%s\n' old-orphan libsox >"$FAKE/unneeded"
    echo libmad >"$FAKE/holds/libsox"
    local family
    for family in RedHat Suse Archlinux; do
        printf '%s\n' old-orphan libsox >"$FAKE/unneeded"
        : >"$FAKE/calls"
        OVOS_UNNEEDED_BEFORE="old-orphan" run bash "$SCRIPT" remove "$family"
        assert_success
        run cat "$FAKE/unneeded"
        assert_output "old-orphan"
        run grep -c "old-orphan" <(grep -E "^(rpm -e|zypper --non-interactive|pacman -R)" "$FAKE/calls")
        assert_output "0"
    done
}

@test "unneeded packages: removal is by name only, never a package manager's own cascade" {
    printf '%s\n' libsox >"$FAKE/unneeded"
    OVOS_UNNEEDED_BEFORE="" run bash "$SCRIPT" remove Suse
    assert_success
    run grep "^zypper --non-interactive" "$FAKE/calls"
    assert_output "zypper --non-interactive remove --no-clean-deps libsox"
}

@test "unneeded packages: nothing new to remove touches nothing" {
    printf '%s\n' old-orphan >"$FAKE/unneeded"
    OVOS_UNNEEDED_BEFORE="old-orphan" run bash "$SCRIPT" remove RedHat
    assert_success
    run grep -c "^rpm" "$FAKE/calls"
    assert_output "0"
}

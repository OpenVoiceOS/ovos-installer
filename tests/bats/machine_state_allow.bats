#!/usr/bin/env bats
#
# What machine_state.sh's own matcher accepts as the runner's or the OS's doing, and
# what it must still report. Every accepted difference is one the uninstall check
# no longer sees, so the edges matter as much as the matches.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    allow_file="$PWD/.github/scripts/machine_state.allow"
    eval "$(sed -n '/^allowed() {/,/^}/p' .github/scripts/machine_state.sh)"
    HOME=/Users/runner
}

@test "machine state: Find My's store directly in ~/Library is macOS's own" {
    allowed home added "$HOME/Library/com.apple.icloud.searchpartyd/CloudStorage.db"
    allowed home removed "$HOME/Library/com.apple.icloud.searchpartyd/CloudStorage.db-wal"
}

@test "machine state: an Apple-looking name directly in ~/Library is still reported" {
    # Anything can take such a name at that level; only a store seen there is accepted.
    run allowed home added "$HOME/Library/com.apple.not-seen-before/state.db"
    assert_failure
    run allowed home removed "$HOME/Library/com.apple.not-seen-before"
    assert_failure
}

@test "machine state: what the installer could have done is still reported" {
    run allowed home added "$HOME/Library/LaunchAgents/org.openvoiceos.core.plist"
    assert_failure
    run allowed home removed "$HOME/Library/Application Support/OpenVoiceOS"
    assert_failure
    # Any program's extension can have a container named by a UUID (#660).
    run allowed home removed "$HOME/Library/Containers/00000000-0000-0000-0000-000000000000/user-data"
    assert_failure
    run allowed home removed "$HOME/.venvs/users-own"
    assert_failure
}

# A formula the install added stays when something that was there before needs it now:
# Homebrew upgraded python@3.14 in place while installing mpv, and 3.14.8_1 needs
# openssl@4. Anything else the install added is still reported.
function needed_by_fixture() {
    eval "$(sed -n '/^needed_by_what_was_there() {/,/^}/p' .github/scripts/machine_state.sh)"
    before="$(mktemp)"
    printf '%s\n' git python@3.14 > "$before"
    function brew() {
        # brew uses --installed --recursive -- <formula>
        case "$5" in
            openssl@4) printf '%s\n' ffmpeg mpv python@3.14 ;;
            sdl3) printf '%s\n' ffmpeg mpv ;;
        esac
    }
}

@test "machine state: a formula the install added stays when what was there before needs it" {
    needed_by_fixture
    run needed_by_what_was_there "$before" openssl@4
    assert_success
    assert_output "python@3.14"
    rm -f "$before"
}

@test "machine state: a formula only what the install added needs is still reported" {
    needed_by_fixture
    run needed_by_what_was_there "$before" sdl3
    assert_failure
    run needed_by_what_was_there "$before" mpv
    assert_failure
    run needed_by_what_was_there "$before" cask:some-app
    assert_failure
    rm -f "$before"
}

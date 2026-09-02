#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    SCRIPT="$PWD/.github/scripts/platform_changes.sh"
    REPO="$(mktemp -d)"
    git -C "$REPO" init -q
    git -C "$REPO" config user.email ci@example.com
    git -C "$REPO" config user.name CI
    mkdir -p "$REPO/seed"
    printf 'seed\n' >"$REPO/seed/file"
    git -C "$REPO" add -A
    git -C "$REPO" commit -qm seed
    BASE="$(git -C "$REPO" rev-parse HEAD)"
}

function teardown() {
    rm -rf "$REPO"
}

# Commit the named paths and ask the script what should run.
function decide() {
    local platform="$1"
    shift
    local path
    for path in "$@"; do
        mkdir -p "$REPO/$(dirname "$path")"
        printf 'change\n' >>"$REPO/$path"
    done
    git -C "$REPO" add -A
    git -C "$REPO" commit -qm change
    (cd "$REPO" && bash "$SCRIPT" "$platform" "$BASE")
}

@test "platform_changes_runs_macos_for_a_launchd_change" {
    run decide macos ansible/roles/ovos_services/tasks/launchd.yml
    assert_output "run=true"
}

@test "platform_changes_skips_linux_for_a_launchd_change" {
    run decide linux ansible/roles/ovos_services/tasks/launchd.yml
    assert_output "run=false"
}

@test "platform_changes_skips_macos_for_a_systemd_change" {
    run decide macos ansible/roles/ovos_services/tasks/systemd.yml
    assert_output "run=false"
}

@test "platform_changes_skips_macos_for_a_containers_change" {
    # The macOS matrix installs virtualenv, so container work cannot affect it.
    run decide macos ansible/roles/ovos_containers/tasks/install.yml
    assert_output "run=false"
}

@test "platform_changes_runs_both_for_shared_code" {
    run decide macos utils/common.sh
    assert_output "run=true"
    run decide linux tui/methods.sh
    assert_output "run=true"
}

@test "platform_changes_runs_when_a_shared_file_joins_a_linux_only_one" {
    # One shared file is enough. Skipping is only safe when every changed
    # file belongs to the other platform.
    run decide macos ansible/roles/ovos_containers/tasks/install.yml utils/common.sh
    assert_output "run=true"
}

@test "platform_changes_still_sees_a_shared_file_in_a_large_change_set" {
    # grep -q stops at its first match. Behind a pipe that leaves the writer
    # with a closed pipe, and pipefail turns the SIGPIPE into the status of
    # the pipeline, which used to flip this answer to run=false once the list
    # outgrew the pipe buffer.
    # git diff --name-only sorts, so the shared file has to sort early for
    # grep to reach its verdict while input is still coming.
    mkdir -p "$REPO/ansible/roles/ovos_config/tasks" "$REPO/ansible/roles/ovos_containers/tasks"
    printf 'change\n' >>"$REPO/ansible/roles/ovos_config/tasks/install.yml"
    local i
    for i in $(seq 1 2000); do
        printf 'change\n' >"$REPO/ansible/roles/ovos_containers/tasks/file_$i.yml"
    done
    git -C "$REPO" add -A
    git -C "$REPO" commit -qm "large change set"

    run bash -c "cd '$REPO' && bash '$SCRIPT' macos '$BASE'"
    assert_output "run=true"
}

@test "platform_changes_runs_when_there_is_no_base_to_compare" {
    run bash -c "cd '$REPO' && bash '$SCRIPT' macos"
    assert_output "run=true"
}

@test "platform_changes_rejects_an_unknown_platform" {
    run bash -c "cd '$REPO' && bash '$SCRIPT' solaris '$BASE'"
    assert_failure
}

@test "documentation-only changes skip the install matrix on both platforms" {
    # A README typo used to run four end-to-end installs and the macOS
    # scenarios, which is an hour of runners for no information.
    assert_equal "$(decide linux README.md)" "run=false"
    assert_equal "$(decide macos README.md)" "run=false"
    assert_equal "$(decide linux docs/troubleshooting.md docs/images/telemetry-os-light.svg)" "run=false"
    assert_equal "$(decide macos LICENSE .github/CODEOWNERS)" "run=false"
}

@test "a documentation change alongside a real one still runs" {
    # The skip is only safe while it means "nothing here can affect an
    # install". One file that can, and the whole set runs.
    assert_equal "$(decide linux README.md ansible/roles/ovos_config/tasks/main.yml)" "run=true"
    assert_equal "$(decide macos docs/macos.md setup.sh)" "run=true"
}

@test "code that only looks like documentation is not treated as documentation" {
    # scripts/ holds audio-calibrate.sh and the translation sync; tests/ and
    # the workflows can change behaviour or the run itself. None of them are
    # prose, whatever their extension.
    assert_equal "$(decide linux scripts/sync_translations.py)" "run=true"
    assert_equal "$(decide linux tests/bats/os.bats)" "run=true"
    assert_equal "$(decide linux .github/workflows/shell_testing.yml)" "run=true"
}

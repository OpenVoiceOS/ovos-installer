#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
}

@test "dialog helper: yesno non-zero does not abort under errexit" {
    local repo_root
    repo_root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

    run env REPO_ROOT="$repo_root" bash -c '
        set -e
        cd "$REPO_ROOT"
        source tui/dialogs.sh

        whiptail() {
            return 1
        }

        if tui_whiptail_dialog --yesno "prompt" 10 10; then
            printf "unexpected-success\n"
        else
            printf "status=%s\n" "$?"
        fi

        printf "survived\n"
    '

    assert_success
    assert_output $'status=1\nsurvived'
}

@test "dialog helper: capture preserves output and status under errexit" {
    local repo_root
    repo_root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

    run env REPO_ROOT="$repo_root" bash -c '
        set -e
        cd "$REPO_ROOT"
        source tui/dialogs.sh

        whiptail() {
            printf "typed-value\n" >&2
            return 255
        }

        if tui_whiptail_capture answer --inputbox "prompt" 10 10 "default"; then
            printf "unexpected-success answer=%s\n" "$answer"
        else
            printf "status=%s answer=%s\n" "$?" "$answer"
        fi

        printf "survived\n"
    '

    assert_success
    assert_output $'status=255 answer=typed-value\nsurvived'
}

@test "dialog helper: allow_escape normalizes ESC under errexit" {
    local repo_root
    repo_root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

    run env REPO_ROOT="$repo_root" bash -c '
        set -e
        cd "$REPO_ROOT"
        source tui/dialogs.sh

        whiptail() {
            return 255
        }

        tui_whiptail_dialog_allow_escape --msgbox "prompt" 10 10
        printf "survived\n"
    '

    assert_success
    assert_output "survived"
}

@test "dialog helper: allow_escape preserves real failures" {
    local repo_root
    repo_root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

    run env REPO_ROOT="$repo_root" bash -c '
        set -e
        cd "$REPO_ROOT"
        source tui/dialogs.sh

        whiptail() {
            return 1
        }

        tui_whiptail_dialog_allow_escape --msgbox "prompt" 10 10
        printf "unreached\n"
    '

    assert_failure
    refute_output --partial "unreached"
}

@test "dialog helper: capture rejects missing output variable" {
    local repo_root
    repo_root="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

    run env REPO_ROOT="$repo_root" bash -c '
        cd "$REPO_ROOT"
        source tui/dialogs.sh
        tui_whiptail_capture
    '

    assert_failure
    assert_output "tui_whiptail_capture: missing output variable"
}

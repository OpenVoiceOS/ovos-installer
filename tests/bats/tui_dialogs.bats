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

@test "dialog sizing: the preferred size is kept when there is no terminal to measure" {
    run env REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)" bash -c '
        cd "$REPO_ROOT"
        source tui/dialogs.sh
        TUI_TTY=/dev/null
        tui_whiptail_fit 35 90
    '

    assert_success
    assert_output "35 90"
}

@test "dialog sizing: a box is fitted to a terminal too small for it" {
    run env REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)" bash -c '
        cd "$REPO_ROOT"
        source tui/dialogs.sh
        # Stand in for a terminal rather than requiring the tests to own one.
        tui_terminal_size() { printf "24 80"; }
        tui_whiptail_fit 35 90 || printf " shrunk"
    '

    assert_success
    # One row for the backtitle and one for the shadow below the box; two
    # columns for the shadow to its right.
    assert_output "22 78 shrunk"
}

@test "dialog sizing: a box never shrinks below a usable size" {
    run env REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)" bash -c '
        cd "$REPO_ROOT"
        source tui/dialogs.sh
        tui_terminal_size() { printf "6 20"; }
        tui_whiptail_fit 35 90 || true
    '

    assert_success
    assert_output "10 40"
}

@test "dialog sizing: whiptail arguments are read the way popt reads them" {
    # The box option does not have to come before its operands, and in this code
    # base it usually does not: the size is the second and third positional
    # argument wherever the flags happen to sit.
    run env REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)" bash -c '
        cd "$REPO_ROOT"
        source tui/dialogs.sh
        args=(--yesno --yes-button Next --no-button Back --title T "body" 35 90)
        tui_whiptail_size_indices args
        printf "|"
        list=(--title T --radiolist "body" --cancel-button Back 35 90 4 a "" ON)
        tui_whiptail_size_indices list
    '

    assert_success
    # text, height, width, list height and option count; -1 and 0 without a list.
    assert_output "7 8 9 -1 0|3 6 7 8 1"
}

@test "dialog sizing: a body that fits keeps the buttons focused" {
    # --scrolltext moves the focus into the text, so Enter stops confirming the
    # screen. It is only worth that when the text would otherwise be invisible.
    run env REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)" bash -c '
        cd "$REPO_ROOT"
        source tui/dialogs.sh
        short="$(printf "a\nb\nc")"
        if tui_whiptail_body_overflows "$short" 35 90 4; then printf "scrolls"; else printf "plain"; fi
        printf " "
        long="$(for i in $(seq 1 40); do printf "line %s\n" "$i"; done)"
        if tui_whiptail_body_overflows "$long" 22 76 4; then printf "scrolls"; else printf "plain"; fi
    '

    assert_success
    assert_output "plain scrolls"
}

@test "dialog sizing: the trailing blank lines of a body are not spent on rows" {
    # The locale templates end every body with a blank line, and whiptail
    # anchors the buttons to the bottom of the box, so those rows buy nothing.
    # The one at the top is the padding under the border and has to survive.
    run env REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)" bash -c '
        cd "$REPO_ROOT"
        source tui/dialogs.sh
        body="$(printf "\nfirst line\nlast line\n\n  \n")"
        tui_whiptail_trim_body "$body" | od -c | head -4
    '

    assert_success
    # Leading newline kept, trailing blank lines gone.
    assert_output --partial '\n   f   i   r   s   t'
    refute_output --partial 'e  \n  \n'
}

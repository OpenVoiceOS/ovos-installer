#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
}

@test "dialog helper: yesno non-zero does not abort under errexit" {
    run bash -lc '
        set -e
        cd "/home/gtrellu/Development/OpenVoiceOS/ovos-installer"
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
    run bash -lc '
        set -e
        cd "/home/gtrellu/Development/OpenVoiceOS/ovos-installer"
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

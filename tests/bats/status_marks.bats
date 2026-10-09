#!/usr/bin/env bats
#
# The status arrow, warning sign and drinks are shown where the terminal can draw them,
# and plain text where they came out as empty squares.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    unset OVOS_INSTALLER_ASCII
}

@test "status marks: a UTF-8 terminal gets the symbols" {
    TERM=xterm-256color OVOS_INSTALLER_TERMINAL_LOCALE=en_US.UTF-8 set_status_marks
    [ "$STATUS_MARK" = "➤" ]
    [ "$WARNING_MARK" = "⚠" ]
    [ "$STARTUP_DRINKS" = " ☕🍵🧋" ]
}

@test "status marks: the Linux console, dumb and serial terminals get plain text" {
    local term
    for term in linux dumb vt100 vt220; do
        TERM="$term" OVOS_INSTALLER_TERMINAL_LOCALE=en_US.UTF-8 set_status_marks
        [ "$STATUS_MARK" = ">" ]
        [ "$WARNING_MARK" = "WARNING:" ]
        [ -z "$STARTUP_DRINKS" ]
    done
}

@test "status marks: a locale that is not UTF-8 gets plain text" {
    TERM=xterm-256color OVOS_INSTALLER_TERMINAL_LOCALE=C set_status_marks
    [ "$STATUS_MARK" = ">" ]
    # No locale at all is not UTF-8 either, whatever setup.sh switched to since.
    TERM=xterm-256color OVOS_INSTALLER_TERMINAL_LOCALE="" LC_ALL=C.UTF-8 set_status_marks
    [ "$STATUS_MARK" = ">" ]
}

@test "status marks: the user's own locale counts, not the one setup.sh switches to" {
    TERM=xterm-256color OVOS_INSTALLER_TERMINAL_LOCALE=POSIX LC_ALL=C.UTF-8 set_status_marks
    [ "$STATUS_MARK" = ">" ]
    TERM=xterm-256color OVOS_INSTALLER_TERMINAL_LOCALE=fr_FR.utf8 LC_ALL=C set_status_marks
    [ "$STATUS_MARK" = "➤" ]
}

@test "status marks: OVOS_INSTALLER_ASCII overrides the guess both ways" {
    OVOS_INSTALLER_ASCII=1 TERM=xterm-256color OVOS_INSTALLER_TERMINAL_LOCALE=en_US.UTF-8 set_status_marks
    [ "$STATUS_MARK" = ">" ]
    OVOS_INSTALLER_ASCII=0 TERM=linux OVOS_INSTALLER_TERMINAL_LOCALE=C set_status_marks
    [ "$STATUS_MARK" = "➤" ]
}

@test "status marks: no message spells a symbol out instead of using the marks" {
    run grep -n -E '➤|⚠|☕|🍵|🧋' setup.sh utils/speech.sh tui/navigation.sh
    assert_failure
    # utils/common.sh holds them once, in set_status_marks.
    run bash -c "grep -n -E '➤|⚠|☕|🍵|🧋' utils/common.sh | grep -v -E 'STATUS_MARK=|WARNING_MARK=|STARTUP_DRINKS=|^[0-9]+:#'"
    assert_failure
}

#!/usr/bin/env bats
#
# The rest of the suite stubs whiptail, which keeps it fast but means nothing
# checks how whiptail itself behaves. These walk the flow through the real
# binary in a pseudo terminal: that the buttons are drawn at the size they are
# given, that the cancel button is where "Back" is wired, and that ESC does
# nothing, because it stopped being a newt form hotkey in 0.52.5.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export REPO_ROOT

    if ! command -v whiptail >/dev/null 2>&1; then
        skip "whiptail is not installed"
    fi
    if ! command -v python3 >/dev/null 2>&1; then
        skip "python3 is not installed"
    fi

    DRIVER="$REPO_ROOT/tests/support/drive_tui.py"
    HARNESS="$REPO_ROOT/tests/support/tui_harness.sh"
}

function drive() {
    local rows="$1"
    local columns="$2"
    shift 2

    python3 "$DRIVER" "$rows" "$columns" "$HARNESS" "$@"
}

@test "whiptail: a comfortable terminal answers every screen with Enter" {
    run drive 45 110 enter enter enter enter enter enter enter enter enter

    assert_success
    assert_line --index 0 $'start\tOpen Voice OS Installation - Welcome'
    assert_line --index 1 $'enter\tOpen Voice OS Installation - Detected'
    assert_line --index 2 $'enter\tOpen Voice OS Installation - Methods'
    assert_line --index 6 $'enter\tOpen Voice OS Installation - Summary'
    assert_output --partial "REACHED_END"
}

@test "whiptail: an 80x24 terminal still draws every screen with its buttons" {
    # The preferred 35x90 box does not fit here. Before the dialogs were fitted
    # to the terminal, whiptail drew them anyway and pushed the buttons off
    # screen, so nothing on this size of window could be answered at all.
    run drive 24 80 enter

    assert_success
    assert_line --index 0 $'start\tOpen Voice OS Installation - Welcome'
    # The welcome screen fits, so Enter confirms it and the walk moves on.
    assert_line --index 1 $'enter\tOpen Voice OS Installation - Detected'
}

@test "whiptail: the cancel button goes back a screen" {
    # tab moves from the default button to the cancel one.
    run drive 45 110 enter enter tab,tab,enter

    assert_success
    assert_line --index 2 $'enter\tOpen Voice OS Installation - Methods'
    # Back out of the methods screen and the detection screen comes back.
    assert_line --index 3 $'tab,tab,enter\tOpen Voice OS Installation - Detected'
}

@test "whiptail: going back from the first screen reaches the language picker" {
    run drive 45 110 tab,enter

    assert_success
    assert_line --index 0 $'start\tOpen Voice OS Installation - Welcome'
    assert_line --index 1 $'tab,enter\tOpen Voice OS Installation - Language'
}

@test "whiptail: leaving from the language picker asks for confirmation" {
    run drive 45 110 tab,enter tab,tab,enter

    assert_success
    assert_line --index 1 $'tab,enter\tOpen Voice OS Installation - Language'
    assert_line --index 2 $'tab,tab,enter\tOpen Voice OS Installation - Quit'
}

@test "whiptail: ESC is never a way forward, whatever this newt does with it" {
    # newt dropped ESC as a default form hotkey in 0.52.5 (Debian #584098), but
    # not every build agrees: on Fedora's 0.52.25 the key does nothing, on
    # Ubuntu's it cancels the dialog. A design that leaned on ESC would work on
    # one and strand the user on the other, which is why the buttons carry the
    # navigation. What has to hold everywhere is that ESC never confirms a
    # screen the user has not answered.
    run drive 45 110 esc

    assert_success
    assert_line --index 0 $'start\tOpen Voice OS Installation - Welcome'
    refute_output --partial "Open Voice OS Installation - Detected"
    refute_output --partial "REACHED_END"
}

@test "whiptail: an existing installation is asked about uninstalling first" {
    EXISTING_INSTANCE="true" INSTANCE_TYPE="virtualenv" run drive 45 110 enter enter tab,enter

    assert_success
    assert_line --index 0 $'start\tOpen Voice OS Installation - Uninstall'
    assert_line --index 1 $'enter\tOpen Voice OS Installation - Update'
    assert_line --index 2 $'enter\tOpen Voice OS Installation - Welcome'
    # And going back reaches them again.
    assert_line --index 3 $'tab,enter\tOpen Voice OS Installation - Update'
}

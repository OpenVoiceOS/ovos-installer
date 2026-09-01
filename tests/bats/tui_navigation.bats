#!/usr/bin/env bats
#
# The installer TUI has to be walkable in both directions: #579 asked for a way
# back to the very beginning and a way out that does not rely on Ctrl-C, which
# whiptail swallows because it puts the terminal in raw mode.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    load ../../utils/constants.sh

    export LOCALE="en-us"

    LOG_FILE="$(mktemp)"
    INSTALLER_STATE_FILE="$(mktemp)"
    rm -f "$INSTALLER_STATE_FILE"
    RUN_AS_HOME="$(mktemp -d)"

    WHIPTAIL_TITLE_LOG="$(mktemp)"
    WHIPTAIL_BACKTITLE_LOG="$(mktemp)"
    WHIPTAIL_CALL_COUNTER="$(mktemp)"
    printf '%s\n' "0" >"$WHIPTAIL_CALL_COUNTER"

    # Dialogs are answered by call number rather than by title: a screen can be
    # shown several times in one walk, and only the sequence says which one the
    # test means.
    WHIPTAIL_CANCEL_CALLS=""
    WHIPTAIL_ESCAPE_CALLS=""
    WHIPTAIL_PREFERRED_TAGS=""

    # A plain x86_64 host with nothing installed, the way the detect_* stages
    # leave the environment before tui/main.sh runs.
    export EXISTING_INSTANCE="false"
    export ARCH="x86_64"
    export DISTRO_NAME="ubuntu"
    export DISTRO_VERSION="Ubuntu 24.04"
    export DISTRO_VERSION_ID="24"
    export DISTRO_LABEL="Ubuntu 24.04"
    export KERNEL="6.8.0"
    export PYTHON="Python 3.12.3"
    export CPU_IS_CAPABLE="true"
    export SOUND_SERVER="PipeWire"
    export DISPLAY_SERVER="wayland"
    export VENV_PATH="$RUN_AS_HOME/.venvs/ovos"
    export RASPBERRYPI_MODEL="N/A"
    export HARDWARE_MODEL="N/A"
    DETECTED_DEVICES=()
    unset INSTANCE_TYPE

    # Stub whiptail. Every dialog is logged, then answered: calls listed in
    # WHIPTAIL_CANCEL_CALLS or WHIPTAIL_ESCAPE_CALLS return that status,
    # anything else is confirmed with a preferred option when the screen offers
    # one and with its first option otherwise.
    whiptail() {
        local args=("$@")
        local j
        local dialog_type=""
        local dialog_title=""
        local backtitle=""
        local call_number=""
        local preselected=""
        local -a tags=()

        call_number="$(( $(cat "$WHIPTAIL_CALL_COUNTER") + 1 ))"
        printf '%s\n' "$call_number" >"$WHIPTAIL_CALL_COUNTER"

        for ((j = 0; j < ${#args[@]}; j++)); do
            case "${args[$j]}" in
                --inputbox|--passwordbox|--yesno|--msgbox|--checklist|--radiolist)
                    dialog_type="${args[$j]#--}"
                    ;;
                --title)
                    dialog_title="${args[$((j + 1))]}"
                    ;;
                --backtitle)
                    backtitle="${args[$((j + 1))]}"
                    ;;
            esac
        done

        printf '%s\t%s\n' "$dialog_type" "$dialog_title" >>"$WHIPTAIL_TITLE_LOG"
        printf '%s\n' "$backtitle" >>"$WHIPTAIL_BACKTITLE_LOG"

        if whiptail_call_listed "$call_number" "$WHIPTAIL_CANCEL_CALLS"; then
            return 1
        fi

        if whiptail_call_listed "$call_number" "$WHIPTAIL_ESCAPE_CALLS"; then
            return 255
        fi

        case "$dialog_type" in
            inputbox|passwordbox)
                printf '%s\n' "answer" >&2
                return 0
                ;;
            yesno|msgbox)
                return 0
                ;;
        esac

        # Lists: hand back a preferred tag when this screen offers one, and its
        # first option otherwise, which is what the screens preselect.
        for ((j = 0; j + 5 < ${#args[@]}; j++)); do
            if [[ "${args[$j]}" =~ ^[0-9]+$ && "${args[$((j + 1))]}" =~ ^[0-9]+$ && "${args[$((j + 2))]}" =~ ^[0-9]+$ ]]; then
                local options_start=$((j + 3))
                local remaining=$(( ${#args[@]} - options_start ))
                local k
                if (( remaining >= 3 && remaining % 3 == 0 )); then
                    for ((k = options_start; k < ${#args[@]}; k += 3)); do
                        tags+=("${args[$k]}")
                        if [ "${args[$((k + 2))]^^}" == "ON" ] && [ -z "$preselected" ]; then
                            preselected="${args[$k]}"
                        fi
                    done
                    break
                fi
            fi
        done

        if [ "${#tags[@]}" -gt 0 ]; then
            # whiptail hands back the selected row, which is the one the screen
            # marked ON unless the user moves.
            local selection="${preselected:-${tags[0]}}"
            local preferred tag
            for preferred in $WHIPTAIL_PREFERRED_TAGS; do
                for tag in "${tags[@]}"; do
                    if [ "$tag" == "$preferred" ]; then
                        selection="$tag"
                        break 2
                    fi
                done
            done
            printf '%s\n' "$selection" >&2
        fi
        return 0
    }
    export -f whiptail whiptail_call_listed

    set -u
}

function teardown() {
    rm -f "$LOG_FILE" "$INSTALLER_STATE_FILE" "$WHIPTAIL_TITLE_LOG" \
        "$WHIPTAIL_BACKTITLE_LOG" "$WHIPTAIL_CALL_COUNTER"
    rm -rf "$RUN_AS_HOME"
}

function whiptail_call_listed() {
    local call_number="$1"
    local listed

    for listed in $2; do
        if [ "$listed" == "$call_number" ]; then
            return 0
        fi
    done

    return 1
}

# The user presses the cancel ("Back") button on the Nth dialog of the walk.
function cancel_on_call() {
    WHIPTAIL_CANCEL_CALLS="${WHIPTAIL_CANCEL_CALLS} $1"
}

function rendered_titles() {
    cut -f2 "$WHIPTAIL_TITLE_LOG"
}

@test "navigation: the cancel button asks the flow to go back" {
    source tui/navigation.sh

    tui_nav_from_status 1

    assert_equal "$TUI_NAV" "back"
}

@test "navigation: confirming the screen moves the flow forward" {
    source tui/navigation.sh

    tui_nav_from_status 0

    assert_equal "$TUI_NAV" "next"
}

@test "navigation: a dialog that cannot render is treated as a cancel" {
    source tui/navigation.sh

    # ESC has not been a newt form hotkey since 0.52.5, so 255 in practice means
    # whiptail failed. Pushing the user forward on it would silently accept a
    # screen they never saw.
    tui_nav_from_status 255

    assert_equal "$TUI_NAV" "back"
}

@test "navigation: a screen this run skips is stepped over in both directions" {
    source tui/navigation.sh

    PROFILE="satellite"
    RASPBERRYPI_MODEL="N/A"
    EXISTING_INSTANCE="false"

    local profiles_index=7
    assert_equal "${TUI_FLOW[$profiles_index]}" "profiles"

    # features is skipped for a satellite, tuning for a non-Raspberry Pi host.
    assert_equal "${TUI_FLOW[$(tui_flow_next_index "$profiles_index")]}" "satellite"
    assert_equal "${TUI_FLOW[$(tui_flow_next_index "$((profiles_index + 2))")]}" "summary"
}

@test "navigation: going back never lands on the hardware confirmation" {
    source tui/navigation.sh

    local detection_index=4
    assert_equal "${TUI_FLOW[$detection_index]}" "detection"

    # hardware_confirmation sits between the two, but it remembers its answer
    # and would bounce the user straight forward again.
    assert_equal "${TUI_FLOW[$(tui_flow_previous_index "$detection_index")]}" "welcome"
}

@test "navigation: nothing precedes the first screen" {
    source tui/navigation.sh

    # welcome is the first screen of a fresh install; the two screens before it
    # in the list only run when an instance already exists.
    EXISTING_INSTANCE="false"
    assert_equal "$(tui_flow_previous_index 2)" "-1"
}

@test "navigation: an existing install starts at the uninstall question" {
    source tui/navigation.sh

    EXISTING_INSTANCE="true"
    CONFIRM_UNINSTALL="false"

    assert_equal "${TUI_FLOW[0]}" "uninstall"
    assert_equal "${TUI_FLOW[1]}" "update"
    # Back from the welcome screen reaches them instead of stopping there.
    assert_equal "${TUI_FLOW[$(tui_flow_previous_index 2)]}" "update"
    assert_equal "$(tui_flow_previous_index 0)" "-1"
}

@test "navigation: the update question is skipped once uninstall is chosen" {
    source tui/navigation.sh

    EXISTING_INSTANCE="true"
    CONFIRM_UNINSTALL="true"

    run tui_flow_step_enabled update
    assert_failure
}

@test "tui: back on the channels screen returns to the methods screen" {
    # 1 welcome, 2 detection, 3 methods, 4 channels.
    cancel_on_call 4

    # shellcheck source=tui/main.sh
    source tui/main.sh

    run rendered_titles
    assert_line --index 2 "Open Voice OS Installation - Methods"
    assert_line --index 3 "Open Voice OS Installation - Channels"
    assert_line --index 4 "Open Voice OS Installation - Methods"
    assert_line --index 5 "Open Voice OS Installation - Channels"
}

@test "tui: back keeps going all the way to the first screen" {
    # Back out of the methods screen, then out of the detection screen it
    # lands on. #579 asked for exactly this: a way back to the beginning.
    cancel_on_call 3
    cancel_on_call 4

    # shellcheck source=tui/main.sh
    source tui/main.sh

    run rendered_titles
    assert_line --index 0 "Open Voice OS Installation - Welcome"
    assert_line --index 1 "Open Voice OS Installation - Detected"
    assert_line --index 2 "Open Voice OS Installation - Methods"
    assert_line --index 3 "Open Voice OS Installation - Detected"
    assert_line --index 4 "Open Voice OS Installation - Welcome"
}

@test "tui: back on the welcome screen returns to the language picker" {
    cancel_on_call 1

    # shellcheck source=tui/main.sh
    source tui/main.sh

    run rendered_titles
    assert_line --index 0 "Open Voice OS Installation - Welcome"
    assert_line --index 1 "Open Voice OS Installation - Language"
    # The picker keeps its selection and the walk resumes from the start.
    assert_line --index 2 "Open Voice OS Installation - Welcome"
    assert_equal "$LOCALE" "en-us"
}

@test "tui: a language chosen on the way back is applied to the rest of the run" {
    cancel_on_call 1
    # The picker answers with whatever it has preselected; make that Basque.
    WHIPTAIL_PREFERRED_TAGS="Basque"

    # shellcheck source=tui/main.sh
    source tui/main.sh

    assert_equal "$LOCALE" "eu-es"

    run rendered_titles
    assert_line --index 1 "Open Voice OS Installation - Language"
    assert_line --index 2 "Ireki Voice OS instalazioa - Ongi etorri"
}

@test "tui: back on the summary screen returns to the feature checklist" {
    # 5 profiles, 6 features, 7 summary.
    cancel_on_call 7

    # shellcheck source=tui/main.sh
    source tui/main.sh

    run rendered_titles
    assert_line --index 6 "Open Voice OS Installation - Summary"
    assert_line --index 7 "Open Voice OS Installation - Features"
    assert_line --index 8 "Open Voice OS Installation - Summary"
}

@test "tui: back on the first satellite question returns to the profiles screen" {
    WHIPTAIL_PREFERRED_TAGS="satellite"
    # 5 profiles, 6 the first HiveMind question.
    cancel_on_call 6

    # shellcheck source=tui/main.sh
    source tui/main.sh

    assert_equal "$PROFILE" "satellite"

    run rendered_titles
    # The HiveMind questions are a sub-flow; backing out of the first one has
    # to leave it rather than bounce inside it.
    assert_line --index 4 "Open Voice OS Installation - Profiles"
    assert_line --index 5 "Open Voice OS Installation - Satellite 1/4"
    assert_line --index 6 "Open Voice OS Installation - Profiles"
}

@test "tui: the telemetry screens can be stepped back out of" {
    # 7 summary, 8 telemetry, then 11 usage metrics on the way forward again.
    cancel_on_call 8
    cancel_on_call 11

    # shellcheck source=tui/main.sh
    source tui/main.sh

    run rendered_titles
    assert_line --index 6 "Open Voice OS Installation - Summary"
    assert_line --index 7 "Open Voice OS Installation - Telemetry"
    assert_line --index 8 "Open Voice OS Installation - Summary"
    assert_line --index 9 "Open Voice OS Installation - Telemetry"
    assert_line --index 10 "Open Voice OS Installation - Usage Metrics"
    assert_line --index 11 "Open Voice OS Installation - Telemetry"
}

@test "tui: leaving the language picker on the way back confirms first" {
    run bash -c '
        set -u
        source utils/constants.sh
        LOG_FILE="$(mktemp)"
        # Reached from the flow, so there are answers to lose.
        export TUI_LANGUAGE_REVISITED="true"

        whiptail() {
            local args=("$@")
            local j title=""
            for ((j = 0; j < ${#args[@]}; j++)); do
                if [ "${args[$j]}" == "--title" ]; then
                    title="${args[$((j + 1))]}"
                fi
            done
            printf "%s\n" "$title"

            case "$title" in
                "Open Voice OS Installation - Language")
                    # The user presses the Exit button.
                    return 1
                    ;;
                *)
                    # ... and confirms on the quit prompt.
                    return 0
                    ;;
            esac
        }

        source tui/language.sh
        printf "unreachable\n"
    '

    assert_success
    assert_output --partial "Open Voice OS Installation - Language"
    assert_output --partial "Open Voice OS Installation - Quit"
    refute_output --partial "unreachable"
}

@test "tui: declining the quit prompt asks for a language again" {
    run bash -c '
        set -u
        source utils/constants.sh
        LOG_FILE="$(mktemp)"
        export TUI_LANGUAGE_REVISITED="true"

        # whiptail runs in a command substitution for list dialogs, so the
        # call counter has to survive a subshell.
        counter_file="$(mktemp)"
        printf "0\n" >"$counter_file"

        whiptail() {
            local args=("$@")
            local j title=""
            for ((j = 0; j < ${#args[@]}; j++)); do
                if [ "${args[$j]}" == "--title" ]; then
                    title="${args[$((j + 1))]}"
                fi
            done
            printf "%s\n" "$title"
            local counter
            counter="$(( $(cat "$counter_file") + 1 ))"
            printf "%s\n" "$counter" >"$counter_file"

            case "$counter" in
                1)
                    # Exit on the language picker.
                    return 1
                    ;;
                2)
                    # "Back" on the quit prompt.
                    return 1
                    ;;
            esac

            printf "English\n" >&2
            return 0
        }

        source tui/language.sh
        printf "LOCALE=%s\n" "$LOCALE"
    '

    assert_success
    assert_output --partial "LOCALE=en-us"
    assert_equal "$(grep -c "Open Voice OS Installation - Language" <<<"$output")" "2"
}

@test "tui: leaving the language picker on the first pass does not ask twice" {
    # Nothing has been answered yet, so a confirmation would only be in the way.
    run bash -c '
        set -u
        source utils/constants.sh
        LOG_FILE="$(mktemp)"

        whiptail() {
            local args=("$@")
            local j title=""
            for ((j = 0; j < ${#args[@]}; j++)); do
                if [ "${args[$j]}" == "--title" ]; then
                    title="${args[$((j + 1))]}"
                fi
            done
            printf "%s\n" "$title"
            # The user presses Exit.
            return 1
        }

        source tui/language.sh
        printf "unreachable\n"
    '

    assert_success
    assert_output "Open Voice OS Installation - Language"
    refute_output --partial "Open Voice OS Installation - Quit"
    refute_output --partial "unreachable"
}

@test "tui: a picker that cannot be drawn stops asking instead of looping" {
    run bash -c '
        set -u
        source utils/constants.sh
        LOG_FILE="$(mktemp)"
        export TUI_LANGUAGE_REVISITED="true"

        calls=0
        whiptail() {
            calls=$((calls + 1))
            if [ "$calls" -gt 50 ]; then
                printf "RUNAWAY\n"
                exit 9
            fi
            return 255
        }

        source tui/language.sh
        printf "unreachable\n"
    '

    # A failure is reported as one: no success status, and no claim that the
    # user cancelled anything.
    assert_failure
    assert_output --partial "could not be drawn"
    refute_output --partial "Installation cancelled"
    refute_output --partial "RUNAWAY"
    refute_output --partial "unreachable"
}

@test "tui: an existing install can walk back through its own prompts" {
    EXISTING_INSTANCE="true"
    INSTANCE_TYPE="virtualenv"
    # 1 uninstall (preselects No), 2 update (preselects Yes), 3 welcome.
    cancel_on_call 3

    # shellcheck source=tui/main.sh
    source tui/main.sh

    run rendered_titles
    assert_line --index 0 "Open Voice OS Installation - Uninstall"
    assert_line --index 1 "Open Voice OS Installation - Update"
    assert_line --index 2 "Open Voice OS Installation - Welcome"
    # Back from the first screen of the install reaches the update question,
    # which is what #579 could not do.
    assert_line --index 3 "Open Voice OS Installation - Update"
}

@test "tui: choosing to uninstall asks nothing else" {
    EXISTING_INSTANCE="true"
    INSTANCE_TYPE="virtualenv"
    WHIPTAIL_PREFERRED_TAGS="yes"
    CONFIRM_UNINSTALL="true"

    # shellcheck source=tui/main.sh
    source tui/main.sh

    assert_equal "$CONFIRM_UNINSTALL" "true"

    run rendered_titles
    assert_output "Open Voice OS Installation - Uninstall"
}

@test "tui: choosing satellite after picking features clears all of them" {
    # Pick features, go back to the profile screen and choose satellite. The
    # satellite has no feature checklist, so anything left set would show up on
    # its summary as a selection the user cannot see or change.
    WHIPTAIL_PREFERRED_TAGS="satellite"
    FEATURE_SKILLS="true"
    FEATURE_EXTRA_SKILLS="true"
    FEATURE_HOMEASSISTANT="true"
    FEATURE_GUI="true"
    FEATURE_LLM="true"

    # shellcheck source=tui/main.sh
    source tui/main.sh

    assert_equal "$PROFILE" "satellite"
    assert_equal "$FEATURE_SKILLS" "false"
    assert_equal "$FEATURE_EXTRA_SKILLS" "false"
    assert_equal "$FEATURE_HOMEASSISTANT" "false"
    assert_equal "$FEATURE_GUI" "false"
    assert_equal "$FEATURE_LLM" "false"
}

@test "tui: an existing install is never asked about telemetry" {
    EXISTING_INSTANCE="true"
    INSTANCE_TYPE="virtualenv"

    # shellcheck source=tui/main.sh
    source tui/main.sh

    run rendered_titles
    refute_output --partial "Open Voice OS Installation - Telemetry"
    refute_output --partial "Open Voice OS Installation - Usage Metrics"
    assert_equal "$SHARE_TELEMETRY" "false"
    assert_equal "$SHARE_USAGE_TELEMETRY" "false"
}

@test "tui: a failed first-run picker retries before giving up" {
    # A transient failure on the very first screen must not end the run on the
    # first try, and when it keeps failing the exit is an error - not the
    # success status a real cancellation uses.
    run bash -c '
        set -u
        source utils/constants.sh
        LOG_FILE="$(mktemp)"
        calls_file="$(mktemp)"
        printf "0\n" >"$calls_file"
        export calls_file

        whiptail() {
            local calls
            calls="$(( $(cat "$calls_file") + 1 ))"
            printf "%s\n" "$calls" >"$calls_file"
            return 255
        }

        source tui/language.sh
        printf "unreachable\n"
    '

    assert_failure
    assert_output --partial "could not be drawn"
    refute_output --partial "Installation cancelled"
    refute_output --partial "unreachable"
}

@test "tui: pressing Exit and changing your mind is never treated as a failure" {
    # Three deliberate Exit-then-stay cycles, then a language is chosen. The
    # bounded retry is for whiptail failing, not for a user hesitating.
    run bash -c '
        set -u
        source utils/constants.sh
        LOG_FILE="$(mktemp)"
        export TUI_LANGUAGE_REVISITED="true"
        calls_file="$(mktemp)"
        printf "0\n" >"$calls_file"
        export calls_file

        whiptail() {
            local calls
            calls="$(( $(cat "$calls_file") + 1 ))"
            printf "%s\n" "$calls" >"$calls_file"
            # Calls alternate picker, confirmation. Cancel all of the first
            # six, then answer the picker.
            if [ "$calls" -le 6 ]; then
                return 1
            fi
            printf "English\n" >&2
            return 0
        }

        source tui/language.sh
        printf "LOCALE=%s\n" "$LOCALE"
    '

    assert_success
    assert_output --partial "LOCALE=en-us"
    refute_output --partial "could not be drawn"
}

@test "tui: a terminal whiptail cannot draw in leaves instead of looping" {
    # Every dialog failing is a real case over SSH: a window too small for the
    # box, or a TERM whiptail does not know. Treating that as a cancel walks
    # the flow back to the language picker, which has to leave rather than ask
    # again with a prompt that cannot be drawn either.
    #
    # The stub counts its own calls rather than leaning on timeout(1), which
    # the macOS runners do not have.
    run bash -c '
        set -u
        source utils/constants.sh
        export LOCALE="en-us"
        LOG_FILE="$(mktemp)"
        INSTALLER_STATE_FILE="$(mktemp)"
        rm -f "$INSTALLER_STATE_FILE"
        RUN_AS_HOME="$(mktemp -d)"
        EXISTING_INSTANCE="false"
        ARCH="x86_64"
        DISTRO_NAME="ubuntu"
        DISTRO_VERSION="Ubuntu 24.04"
        DISTRO_VERSION_ID="24"
        DISTRO_LABEL="Ubuntu 24.04"
        KERNEL="6.8.0"
        PYTHON="Python 3.12.3"
        CPU_IS_CAPABLE="true"
        SOUND_SERVER="PipeWire"
        DISPLAY_SERVER="wayland"
        VENV_PATH="$RUN_AS_HOME/.venvs/ovos"
        RASPBERRYPI_MODEL="N/A"
        HARDWARE_MODEL="N/A"
        DETECTED_DEVICES=()

        calls=0
        whiptail() {
            calls=$((calls + 1))
            if [ "$calls" -gt 200 ]; then
                printf "RUNAWAY\n"
                exit 9
            fi
            return 255
        }

        source tui/main.sh
        printf "unreachable\n"
    '

    assert_failure
    assert_output --partial "could not be drawn"
    refute_output --partial "RUNAWAY"
    refute_output --partial "unreachable"
}

@test "tui: every dialog carries the navigation hint in its backtitle" {
    # shellcheck source=tui/main.sh
    source tui/main.sh

    run sort -u "$WHIPTAIL_BACKTITLE_LOG"
    assert_output "Back: previous screen  -  keep going back to leave"
}

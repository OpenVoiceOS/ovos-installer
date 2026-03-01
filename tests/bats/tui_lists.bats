#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    load ../../utils/constants.sh

    # TUI defaults used by the scripts
    export LOCALE="en-us"
    # shellcheck source=tui/locales/en-us/misc.sh
    source tui/locales/en-us/misc.sh

    LOG_FILE="$(mktemp)"
    INSTALLER_STATE_FILE="$(mktemp)"
    rm -f "$INSTALLER_STATE_FILE"
    WHIPTAIL_SPY_FILE="$(mktemp)"

    export EXISTING_INSTANCE="false"
    export ARCH="x86_64"
    export RASPBERRYPI_MODEL="N/A"
    export DISTRO_NAME="ubuntu"
    DETECTED_DEVICES=()

    # Whiptail spy values (written from subshells via $WHIPTAIL_SPY_FILE)
    WHIPTAIL_FORCE_SELECTION=""
    printf '%s\n' "list_height=0" "option_count=0" "tags=" >"$WHIPTAIL_SPY_FILE"

    # Minimal whiptail stub that validates list arguments and returns a selection.
    whiptail() {
        local args=("$@")
        local j k

        # Find the "height width list-height" triple that precedes (tag item status)*.
        for ((j = 0; j + 5 < ${#args[@]}; j++)); do
            if [[ "${args[$j]}" =~ ^[0-9]+$ && "${args[$((j + 1))]}" =~ ^[0-9]+$ && "${args[$((j + 2))]}" =~ ^[0-9]+$ ]]; then
                local options_start=$((j + 3))
                local remaining=$(( ${#args[@]} - options_start ))

                if (( remaining >= 3 && remaining % 3 == 0 )); then
                    # Validate status fields and collect tags.
                    local -a parsed_tags=()
                    for ((k = options_start; k < ${#args[@]}; k += 3)); do
                        local tag="${args[$k]}"
                        local status="${args[$((k + 2))]}"

                        # Tag must be non-empty to avoid blank lists.
                        if [ -z "$tag" ]; then
                            echo "whiptail: empty tag detected" >&2
                            return 2
                        fi

                        case "$status" in
                            on|off|ON|OFF) ;;
                            *)
                                echo "whiptail: invalid status '$status'" >&2
                                return 2
                                ;;
                        esac

                        parsed_tags+=("$tag")
                    done

                    local parsed_list_height="${args[$((j + 2))]}"
                    local parsed_option_count="$(( remaining / 3 ))"

                    if [ "$parsed_list_height" -lt 1 ]; then
                        echo "whiptail: list-height must be >= 1" >&2
                        return 2
                    fi

                    # Persist parsed args to a file because whiptail is called in a subshell.
                    {
                        printf 'list_height=%s\n' "$parsed_list_height"
                        printf 'option_count=%s\n' "$parsed_option_count"
                        printf 'tags=%s\n' "${parsed_tags[*]}"
                    } >"$WHIPTAIL_SPY_FILE"

                    local selection="${WHIPTAIL_FORCE_SELECTION:-${parsed_tags[0]}}"
                    printf '%s\n' "$selection" >&2
                    return 0
                fi
            fi
        done

        # Non-list dialogs: succeed with no output.
        return 0
    }
    export -f whiptail
}

function spy_value() {
    local key="$1"
    awk -F= -v k="$key" '$1==k {print $2; exit}' "$WHIPTAIL_SPY_FILE"
}

@test "channels: shows all options when navigating back in a new install" {
    printf '%s\n' '{"channel":"testing"}' >"$INSTALLER_STATE_FILE"
    EXISTING_INSTANCE="false"
    WHIPTAIL_FORCE_SELECTION="testing"

    # shellcheck source=tui/channels.sh
    source tui/channels.sh

    assert_equal "$(spy_value option_count)" "3"
    assert_equal "$(spy_value list_height)" "4"
}

@test "channels: locks selection for an existing install" {
    printf '%s\n' '{"channel":"testing"}' >"$INSTALLER_STATE_FILE"
    EXISTING_INSTANCE="true"
    WHIPTAIL_FORCE_SELECTION="testing"

    # shellcheck source=tui/channels.sh
    source tui/channels.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
}

@test "channels: hides non-alpha channels on Mark 2 hardware" {
    EXISTING_INSTANCE="false"
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION="alpha"

    # shellcheck source=tui/channels.sh
    source tui/channels.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "alpha"
}

@test "profiles: shows all options when navigating back in a new install" {
    printf '%s\n' '{"profile":"ovos"}' >"$INSTALLER_STATE_FILE"
    EXISTING_INSTANCE="false"
    WHIPTAIL_FORCE_SELECTION="ovos"

    # shellcheck source=tui/profiles.sh
    source tui/profiles.sh

    assert_equal "$(spy_value option_count)" "4"
    assert_equal "$(spy_value list_height)" "4"
}

@test "profiles: locks selection for an existing install" {
    printf '%s\n' '{"profile":"ovos"}' >"$INSTALLER_STATE_FILE"
    EXISTING_INSTANCE="true"
    WHIPTAIL_FORCE_SELECTION="ovos"

    # shellcheck source=tui/profiles.sh
    source tui/profiles.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
}

@test "methods: never renders an empty radiolist (guards invalid INSTANCE_TYPE)" {
    EXISTING_INSTANCE="true"
    INSTANCE_TYPE="not-a-method"
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    # On x86_64 with no other restrictions, both methods are available.
    assert_equal "$(spy_value option_count)" "2"
    assert_equal "$(spy_value list_height)" "4"
}

@test "methods: hides containers on macOS" {
    DISTRO_NAME="macos"
    EXISTING_INSTANCE="false"
    INSTANCE_TYPE=""
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "virtualenv"
}

@test "methods: keeps containers hidden on macOS for existing container installs" {
    DISTRO_NAME="macos"
    EXISTING_INSTANCE="true"
    INSTANCE_TYPE="containers"
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "virtualenv"
}

@test "methods: hides containers on Mark 2 hardware" {
    EXISTING_INSTANCE="false"
    INSTANCE_TYPE=""
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "virtualenv"
}

@test "methods: keeps containers hidden on Mark 2 for existing container installs" {
    EXISTING_INSTANCE="true"
    INSTANCE_TYPE="containers"
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "virtualenv"
}

@test "methods: does not apply Mark 2 restriction to DevKit detection" {
    EXISTING_INSTANCE="false"
    INSTANCE_TYPE=""
    DETECTED_DEVICES=("attiny1614" "tas5806")
    WHIPTAIL_FORCE_SELECTION="containers"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    assert_equal "$(spy_value option_count)" "2"
    assert_equal "$(spy_value list_height)" "4"
}

@test "features: checklist always has non-zero list-height and options" {
    printf '%s\n' '{"profile":"ovos","channel":"testing","features":["skills"]}' >"$INSTALLER_STATE_FILE"
    PROFILE="ovos"
    WHIPTAIL_FORCE_SELECTION="skills"

    # shellcheck source=tui/features.sh
    source tui/features.sh

    assert_equal "$(spy_value option_count)" "3"
    assert_equal "$(spy_value list_height)" "4"
}

@test "features: forces GUI on Debian Trixie Mark 2 hardware" {
    PROFILE="ovos"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION="skills"

    # shellcheck source=tui/features.sh
    source tui/features.sh

    assert_equal "$(spy_value option_count)" "4"
    tags="$(spy_value tags)"
    if [[ "$tags" != *gui* ]]; then
        echo "expected gui in tag list: $tags" >&2
        return 1
    fi
    assert_equal "$FEATURE_GUI" "true"
}

@test "features: shows Home Assistant option for containers installs" {
    printf '%s\n' '{"profile":"ovos","channel":"testing","features":["skills"]}' >"$INSTALLER_STATE_FILE"
    PROFILE="ovos"
    METHOD="containers"
    WHIPTAIL_FORCE_SELECTION="skills"

    # shellcheck source=tui/features.sh
    source tui/features.sh

    assert_equal "$(spy_value option_count)" "3"
    assert_equal "$(spy_value list_height)" "4"

    tags="$(spy_value tags)"
    if [[ "$tags" != *homeassistant* ]]; then
        echo "expected homeassistant in tag list: $tags" >&2
        return 1
    fi
}

@test "tuning: radiolist is well-formed (list-height >= 1, options present)" {
    WHIPTAIL_FORCE_SELECTION="no"

    # shellcheck source=tui/locales/en-us/tuning.sh
    source tui/locales/en-us/tuning.sh
    # shellcheck source=tui/tuning.sh
    source tui/tuning.sh

    assert_equal "$(spy_value option_count)" "2"
    assert_equal "$(spy_value list_height)" "4"
}

function teardown() {
    rm -f "$LOG_FILE" "$INSTALLER_STATE_FILE" "$WHIPTAIL_SPY_FILE"
}

#!/usr/bin/env bats
# Tests for scenario.sh functions
# Following BATS best practices for comprehensive test coverage

setup() {
    # Load BATS testing framework
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    # Load source files under test
    load ../../utils/constants.sh
    load ../../utils/common.sh
    load ../../utils/scenario.sh

    # Set up test environment
    export LOG_FILE="/tmp/ovos-installer-test.log"
    export YQ_BINARY_PATH="/tmp/yq-test"
    export SCENARIO_NAME="scenario.yaml"

    # Create a test scenario file
    export SCENARIO_PATH="/tmp/test-scenario.yaml"

    # Clean up any existing test artifacts
    rm -f "$LOG_FILE" "$YQ_BINARY_PATH" "$SCENARIO_PATH"
}

teardown() {
    # Clean up test artifacts
    rm -f "$LOG_FILE" "$YQ_BINARY_PATH" "$SCENARIO_PATH"

    # Reset global variables that may have been modified
    unset SCENARIO_NOT_SUPPORTED UNINSTALL METHOD CHANNEL PROFILE TUNING
    unset SHARE_TELEMETRY SHARE_USAGE_TELEMETRY
    unset FEATURE_SKILLS FEATURE_GUI FEATURE_EXTRA_SKILLS
    unset HIVEMIND_HOST HIVEMIND_PORT SATELLITE_KEY SATELLITE_PASSWORD
}

# Test download_yq function
@test "download_yq_successful_download" {
    ARCH="x86_64"
    function uname() {
        case "$1" in
            "-m") echo "x86_64" ;;
            "-s") echo "Linux" ;;
        esac
    }
    function curl() {
        # Simulate successful download
        touch "$YQ_BINARY_PATH"
        return 0
    }
    export -f uname curl

    run download_yq
    assert_success
    assert [ -x "$YQ_BINARY_PATH" ]

    unset -f uname curl
}

@test "download_yq_existing_file_replacement" {
    ARCH="x86_64"
    # Create existing file
    echo "old content" > "$YQ_BINARY_PATH"

    function uname() {
        case "$1" in
            "-m") echo "x86_64" ;;
            "-s") echo "Linux" ;;
        esac
    }
    function curl() {
        # Simulate successful download - overwrite file
        echo "new content" > "$YQ_BINARY_PATH"
        return 0
    }
    export -f uname curl

    run download_yq
    assert_success
    assert_equal "$(cat "$YQ_BINARY_PATH")" "new content"

    unset -f uname curl
}

@test "download_yq_download_failure" {
    ARCH="x86_64"
    function uname() {
        case "$1" in
            "-m") echo "x86_64" ;;
            "-s") echo "Linux" ;;
        esac
    }
    function curl() {
        return 1  # Simulate download failure
    }
    export -f uname curl

    run download_yq
    assert_failure

    unset -f uname curl
}

@test "download_yq_armv7l_arch_mapping" {
    ARCH="armv7l"
    export ARCH

    function uname() {
        case "$1" in
        "-s") echo "Linux" ;;
        esac
    }
    function curl() {
        printf '%s\n' "$*" > /tmp/ovos-curl-args
        touch "$YQ_BINARY_PATH"
        return 0
    }
    export -f uname curl

    run download_yq
    assert_success
    assert [ -x "$YQ_BINARY_PATH" ]

    run cat /tmp/ovos-curl-args
    assert_success
    assert_output --partial "yq_linux_arm"

    rm -f /tmp/ovos-curl-args
    unset -f uname curl
    unset ARCH
}

# Test detect_scenario function
@test "detect_scenario_no_scenario_file" {
    export RUN_AS_HOME="/nonexistent/home"

    # Mock download_yq to avoid actual download
    function download_yq() {
        return 0
    }
    export -f download_yq

    # Call directly to test variable setting
    detect_scenario
    assert_equal "$SCENARIO_FOUND" "false"

    unset -f download_yq
}

@test "detect_scenario_with_valid_scenario" {
    export RUN_AS_HOME="/tmp/test-home"
    mkdir -p "$RUN_AS_HOME/.config/ovos-installer"

    # Create a valid scenario file
    cat <<EOF >"$RUN_AS_HOME/.config/ovos-installer/scenario.yaml"
uninstall: false
method: containers
channel: testing
profile: ovos
features:
  skills: true
raspberry_pi_tuning: true
share_telemetry: true
share_usage_telemetry: true
EOF

    function download_yq() {
        # Create dummy yq binary
        echo "#!/bin/bash" > "$YQ_BINARY_PATH"
        echo "exit 0" >> "$YQ_BINARY_PATH"
        chmod +x "$YQ_BINARY_PATH"
        return 0
    }
    function in_array() {
        return 0  # All validations pass
    }
    export -f download_yq in_array

    # Mock source to simulate successful scenario processing
    function source() {
        export SCENARIO_NOT_SUPPORTED="false"
        export UNINSTALL="false"
        export METHOD="containers"
    }
    export -f source

    detect_scenario
    assert_equal "$SCENARIO_FOUND" "true"

    unset -f download_yq in_array source
    rm -rf "$RUN_AS_HOME"
}

@test "detect_scenario_with_invalid_scenario" {
    export RUN_AS_HOME="/tmp/test-home-invalid"
    mkdir -p "$RUN_AS_HOME/.config/ovos-installer"

    # Create an invalid scenario file
    cat <<EOF >"$RUN_AS_HOME/.config/ovos-installer/scenario.yaml"
uninstall: false
invalid_option: true
EOF

    function download_yq() {
        # Create dummy yq binary
        echo "#!/bin/bash" > "$YQ_BINARY_PATH"
        echo "exit 0" >> "$YQ_BINARY_PATH"
        chmod +x "$YQ_BINARY_PATH"
        return 0
    }
    function in_array() {
        if [[ "$2" == "invalid_option" ]]; then
            return 1  # This option is invalid
        fi
        return 0
    }
    export -f download_yq in_array

    # Mock source to simulate scenario processing failure
    function source() {
        export SCENARIO_NOT_SUPPORTED="true"
    }
    export -f source

    # Mock on_error to prevent actual error handling
    function on_error() {
        export SCENARIO_FOUND="false"
        # Exit with failure status as expected
        exit 1
    }
    export -f on_error

    run detect_scenario
    assert_failure  # Function should fail due to invalid scenario
    # Note: SCENARIO_FOUND variable not testable when function exits

    unset -f download_yq in_array source on_error
    rm -rf "$RUN_AS_HOME"
}

# Test in_array function
@test "in_array_element_found" {
    local test_array=("apple" "banana" "cherry")
    run in_array test_array "banana"
    assert_success
}

@test "in_array_element_not_found" {
    local test_array=("apple" "banana" "cherry")

    # Mock on_error to capture the error message
    function on_error() {
        echo "grape is an unsupported option"
        exit 1
    }
    export -f on_error

    run in_array test_array "grape"
    assert_failure
    assert_output --partial "grape is an unsupported option"

    unset -f on_error
}

# Test wsl2_requirements function
@test "wsl2_requirements_not_wsl2" {
    export KERNEL="linux"
    run wsl2_requirements
    assert_success
}

@test "wsl2_requirements_wsl2_with_systemd" {
    export KERNEL="microsoft"
    export WSL_FILE="/tmp/wsl-test.conf"

    # Create WSL config with systemd enabled
    echo -e "[boot]\nsystemd=true" > "$WSL_FILE"

    run wsl2_requirements
    assert_success
    assert_output --partial "Validating WSL2 requirements"

    rm -f "$WSL_FILE"
}

@test "wsl2_requirements_wsl2_without_systemd" {
    export KERNEL="microsoft"
    export WSL_FILE="/tmp/wsl-test.conf"

    # Create WSL config without systemd
    echo -e "[boot]\ncommandline=quiet" > "$WSL_FILE"

    run wsl2_requirements
    assert_failure
    # Check that the error message was written to LOG_FILE
    assert [ -f "$LOG_FILE" ]
    grep -q "systemd=true must be added" "$LOG_FILE"

    rm -f "$WSL_FILE"
}

# Test ver function (version comparison helper)
@test "ver_basic_version" {
    result="$(ver "1.2.3")"
    assert_equal "$result" "001002003"
}

@test "ver_single_digit" {
    result="$(ver "5")"
    assert_equal "$result" "005"
}

@test "ver_two_digits" {
    result="$(ver "3.9")"
    assert_equal "$result" "003009"
}

@test "ver_with_leading_zero" {
    result="$(ver "1.02.3")"
    assert_equal "$result" "001002003"
}

# The gui feature reached the scenario parser late: the TUI has always offered it
# and setup.sh has always passed ovos_installer_feature_gui, but SCENARIO_ALLOWED_FEATURES
# did not list it, so a scenario naming gui at all was refused whatever its value.
@test "scenario_feature_gui_is_accepted" {
    # load() ran constants.sh inside setup(), where declare made the
    # allow-lists local; re-declare them here so in_array can see them
    source "$BATS_TEST_DIRNAME"/../../utils/constants.sh
    export SCENARIO_PATH="/tmp/test-scenario-gui.yaml"
    cat <<EOF >"$SCENARIO_PATH"
uninstall: false
method: containers
channel: testing
profile: server
features:
  skills: true
  gui: false
raspberry_pi_tuning: false
share_telemetry: true
share_usage_telemetry: true
EOF
    cat <<'EOF' >"$YQ_BINARY_PATH"
#!/usr/bin/env bash
case "$*" in
*".features | to_entries"*) echo "skills=true"; echo "gui=false" ;;
*".hivemind | to_entries"*|*".llm | to_entries"*) ;;
*) echo "uninstall=false"; echo "method=containers"; echo "channel=testing"
   echo "profile=server"; echo "features="; echo "raspberry_pi_tuning=false"
   echo "share_telemetry=true"; echo "share_usage_telemetry=true" ;;
esac
EOF
    chmod +x "$YQ_BINARY_PATH"

    # detect_scenario primes this before sourcing; mirror it so the test
    # exercises the same starting state as the installer
    export SCENARIO_NOT_SUPPORTED="false"
    source "$BATS_TEST_DIRNAME"/../../utils/scenario.sh

    assert_equal "$SCENARIO_NOT_SUPPORTED" "false"
    assert_equal "$FEATURE_GUI" "false"
    assert_equal "$FEATURE_SKILLS" "true"
    rm -f "$SCENARIO_PATH"
}

@test "scenario_feature_gui_true_is_mapped" {
    # load() ran constants.sh inside setup(), where declare made the
    # allow-lists local; re-declare them here so in_array can see them
    source "$BATS_TEST_DIRNAME"/../../utils/constants.sh
    export SCENARIO_PATH="/tmp/test-scenario-gui-on.yaml"
    echo "placeholder" >"$SCENARIO_PATH"
    cat <<'EOF' >"$YQ_BINARY_PATH"
#!/usr/bin/env bash
case "$*" in
*".features | to_entries"*) echo "gui=true" ;;
*".hivemind | to_entries"*|*".llm | to_entries"*) ;;
*) echo "uninstall=false"; echo "method=containers"; echo "channel=testing"
   echo "profile=ovos"; echo "features="; echo "raspberry_pi_tuning=false"
   echo "share_telemetry=true"; echo "share_usage_telemetry=true" ;;
esac
EOF
    chmod +x "$YQ_BINARY_PATH"

    # detect_scenario primes this before sourcing; mirror it so the test
    # exercises the same starting state as the installer
    export SCENARIO_NOT_SUPPORTED="false"
    source "$BATS_TEST_DIRNAME"/../../utils/scenario.sh

    assert_equal "$SCENARIO_NOT_SUPPORTED" "false"
    assert_equal "$FEATURE_GUI" "true"
    rm -f "$SCENARIO_PATH"
}

# A refused value used to leave nothing but "scenario not supported" in the log,
# with no way to tell which line of the file to edit.
@test "scenario_rejection_records_the_offending_value" {
    # load() ran constants.sh inside setup(), where declare made the
    # allow-lists local; re-declare them here so in_array can see them
    source "$BATS_TEST_DIRNAME"/../../utils/constants.sh
    export SCENARIO_PATH="/tmp/test-scenario-channel.yaml"
    echo "placeholder" >"$SCENARIO_PATH"
    cat <<'EOF' >"$YQ_BINARY_PATH"
#!/usr/bin/env bash
case "$*" in
*".features | to_entries"*) echo "skills=true" ;;
*".hivemind | to_entries"*|*".llm | to_entries"*) ;;
*) echo "uninstall=false"; echo "method=containers"; echo "channel=development"
   echo "profile=server"; echo "features="; echo "raspberry_pi_tuning=false"
   echo "share_telemetry=true"; echo "share_usage_telemetry=true" ;;
esac
EOF
    chmod +x "$YQ_BINARY_PATH"

    # detect_scenario primes this before sourcing; mirror it so the test
    # exercises the same starting state as the installer
    export SCENARIO_NOT_SUPPORTED="false"
    source "$BATS_TEST_DIRNAME"/../../utils/scenario.sh

    assert_equal "$SCENARIO_NOT_SUPPORTED" "true"
    assert_equal "$SCENARIO_ERROR" "channel: development (expected: testing, alpha)"
    rm -f "$SCENARIO_PATH"
}

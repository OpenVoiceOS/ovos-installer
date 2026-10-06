#!/usr/bin/env bats
#
# Local speech is offered on a Raspberry Pi 5 with 8 GB or a machine at least as
# capable, on alpha virtualenv installs only. Everything else stays on the
# public servers, whatever was asked for.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/speech.sh

    LOG_FILE="$(mktemp)"

    # A 64-bit Linux host with AVX2 and 16 GB, which can run local speech.
    CPU_IS_CAPABLE="true"
    RASPBERRYPI_MODEL="N/A"
    TOTAL_MEMORY_MB=16000
    MOCK_UNAME_S="Linux"
    MOCK_UNAME_M="x86_64"
    MOCK_LONG_BIT="64"

    function uname() {
        case "$1" in
            -s) printf '%s\n' "$MOCK_UNAME_S" ;;
            -m) printf '%s\n' "$MOCK_UNAME_M" ;;
        esac
    }
    function getconf() {
        printf '%s\n' "$MOCK_LONG_BIT"
    }
}

function teardown() {
    rm -f "$LOG_FILE"
    unset -f uname getconf sysctl
}

@test "speech: a capable 64-bit Linux machine with 16 GB can run local speech" {
    run local_speech_hardware_supported
    assert_success
}

@test "speech: a Raspberry Pi 5 with 8 GB can run local speech" {
    MOCK_UNAME_M="aarch64"
    RASPBERRYPI_MODEL="Raspberry Pi 5 Model B Rev 1.0"
    # What an 8 GB board reports once firmware and kernel have taken their share.
    TOTAL_MEMORY_MB=8052

    run local_speech_hardware_supported
    assert_success
}

@test "speech: the Pi 500 and the Compute Module 5 count as a Pi 5" {
    MOCK_UNAME_M="aarch64"
    TOTAL_MEMORY_MB=8052

    RASPBERRYPI_MODEL="Raspberry Pi 500 Rev 1.0"
    run local_speech_hardware_supported
    assert_success

    RASPBERRYPI_MODEL="Raspberry Pi Compute Module 5 Rev 1.0"
    run local_speech_hardware_supported
    assert_success
}

@test "speech: a Raspberry Pi 5 with 4 GB stays public" {
    MOCK_UNAME_M="aarch64"
    RASPBERRYPI_MODEL="Raspberry Pi 5 Model B Rev 1.0"
    TOTAL_MEMORY_MB=4040

    run local_speech_hardware_supported
    assert_failure
}

@test "speech: a Raspberry Pi 4 stays public even with 8 GB" {
    MOCK_UNAME_M="aarch64"
    RASPBERRYPI_MODEL="Raspberry Pi 4 Model B Rev 1.5"
    TOTAL_MEMORY_MB=7810

    run local_speech_hardware_supported
    assert_failure
}

@test "speech: the memory floor is 7.5 GiB" {
    TOTAL_MEMORY_MB=7680
    run local_speech_hardware_supported
    assert_success

    TOTAL_MEMORY_MB=7679
    run local_speech_hardware_supported
    assert_failure
}

@test "speech: a CPU without AVX2 or NEON stays public" {
    CPU_IS_CAPABLE="false"

    run local_speech_hardware_supported
    assert_failure
}

@test "speech: a 32-bit userland stays public" {
    MOCK_UNAME_M="aarch64"
    MOCK_LONG_BIT="32"
    RASPBERRYPI_MODEL="Raspberry Pi 5 Model B Rev 1.0"
    TOTAL_MEMORY_MB=8052

    run local_speech_hardware_supported
    assert_failure
}

@test "speech: an Intel Mac stays public and an Apple silicon Mac does not" {
    MOCK_UNAME_S="Darwin"

    MOCK_UNAME_M="x86_64"
    run local_speech_hardware_supported
    assert_failure

    MOCK_UNAME_M="arm64"
    run local_speech_hardware_supported
    assert_success
}

@test "speech: memory on a Mac is read from hw.memsize" {
    MOCK_UNAME_S="Darwin"
    function sysctl() {
        printf '%s\n' "17179869184"
    }

    run total_memory_mb
    assert_success
    assert_output "16384"
}

@test "speech: detection exports whether this host is capable" {
    MOCK_UNAME_S="Darwin"
    MOCK_UNAME_M="arm64"
    function sysctl() {
        printf '%s\n' "8589934592"
    }

    detect_local_speech_support >/dev/null
    assert_equal "$TOTAL_MEMORY_MB" "8192"
    assert_equal "$LOCAL_SPEECH_CAPABLE" "true"

    function sysctl() {
        printf '%s\n' "4294967296"
    }
    detect_local_speech_support >/dev/null
    assert_equal "$LOCAL_SPEECH_CAPABLE" "false"
}

@test "speech: local is only available on alpha installs with audio" {
    LOCAL_SPEECH_CAPABLE="true"
    CHANNEL="alpha"
    METHOD="virtualenv"
    PROFILE="ovos"
    run local_speech_available
    assert_success

    PROFILE="satellite"
    run local_speech_available
    assert_success

    PROFILE="server"
    run local_speech_available
    assert_failure

    PROFILE="ovos"
    CHANNEL="testing"
    run local_speech_available
    assert_failure

    CHANNEL="alpha"
    METHOD="virtualenv"
    LOCAL_SPEECH_CAPABLE="false"
    run local_speech_available
    assert_failure
}

@test "speech: an available local choice is kept" {
    LOCAL_SPEECH_CAPABLE="true"
    CHANNEL="alpha"
    METHOD="virtualenv"
    PROFILE="ovos"
    SPEECH_ENGINE="local"

    normalize_speech_engine
    assert_equal "$SPEECH_ENGINE" "local"
}

@test "speech: local where it is not available falls back to public and says so" {
    LOCAL_SPEECH_CAPABLE="true"
    CHANNEL="testing"
    METHOD="virtualenv"
    PROFILE="ovos"
    SPEECH_ENGINE="local"

    run normalize_speech_engine
    assert_success
    assert_output --partial "Using the public servers instead"

    normalize_speech_engine >/dev/null
    assert_equal "$SPEECH_ENGINE" "public"
}

@test "speech: nothing chosen means public" {
    unset SPEECH_ENGINE
    LOCAL_SPEECH_CAPABLE="true"
    CHANNEL="alpha"
    METHOD="virtualenv"
    PROFILE="ovos"

    run normalize_speech_engine
    assert_output ""

    normalize_speech_engine
    assert_equal "$SPEECH_ENGINE" "public"
}

function run_scenario_with_speech_engine() {
    local value="$1"
    local scenario_file yq_mock
    scenario_file="$(mktemp)"
    yq_mock="$(mktemp)"

    printf 'speech_engine: %s\n' "$value" >"$scenario_file"
    {
        printf '%s\n' '#!/usr/bin/env bash'
        printf '%s\n' 'if [ "$1" = '"'"'to_entries | map([.key, .value] | join("=")) | .[]'"'"' ]; then'
        printf '%s\n' '    printf "%s\n" uninstall=false method=virtualenv channel=alpha profile=ovos features=enabled raspberry_pi_tuning=false share_telemetry=false share_usage_telemetry=false'
        printf '    printf "%%s\\n" speech_engine=%s\n' "$value"
        printf '%s\n' 'elif [ "$1" = '"'"'.features | to_entries | map([.key, .value] | join("=")) | .[]'"'"' ]; then'
        printf '%s\n' '    printf "%s\n" skills=true'
        printf '%s\n' 'fi'
    } >"$yq_mock"
    chmod +x "$yq_mock"

    run bash -c '
        cd "$1"
        source utils/constants.sh
        source utils/common.sh
        export SCENARIO_PATH="$2"
        export YQ_BINARY_PATH="$3"
        source utils/scenario.sh
        printf "%s|%s|%s\n" "${SPEECH_ENGINE:-unset}" "${SCENARIO_NOT_SUPPORTED:-false}" "${SCENARIO_ERROR:-}"
    ' bash "$BATS_TEST_DIRNAME/../.." "$scenario_file" "$yq_mock"

    rm -f "$scenario_file" "$yq_mock"
}

@test "speech: a scenario can ask for local or public speech" {
    run_scenario_with_speech_engine "local"
    assert_success
    assert_output "local|false|"

    run_scenario_with_speech_engine "public"
    assert_success
    assert_output "public|false|"
}

@test "speech: a scenario with an unknown speech engine is rejected" {
    run_scenario_with_speech_engine "offline"
    assert_success
    assert_output "unset|true|speech_engine: offline (expected: local, public)"
}

@test "speech: containers get local speech for the ovos and listener profiles only" {
    LOCAL_SPEECH_CAPABLE="true"
    CHANNEL="alpha"
    METHOD="containers"

    PROFILE="ovos"
    run local_speech_available
    assert_success

    PROFILE="listener"
    run local_speech_available
    assert_success

    # A containers satellite runs hivemind-docker, whose images carry no speech plugins.
    PROFILE="satellite"
    run local_speech_available
    assert_failure

    PROFILE="server"
    run local_speech_available
    assert_failure

    PROFILE="ovos"
    CHANNEL="testing"
    run local_speech_available
    assert_failure
}

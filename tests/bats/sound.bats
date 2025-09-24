#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    RUN_AS_UID="1000"
    RUN_AS_HOME="/home/testuser"
    RUN_AS="testuser"
}

@test "function_detect_sound_pulseaudio" {
    function pgrep() {
        echo "pulse"
    }
    function command() {
        return 0
    }
    function pactl() {
        echo "Server Name: pulseaudio"
    }
    export -f pgrep command pactl
    detect_sound
    assert_equal "$SOUND_SERVER" "pulseaudio"
    unset pgrep command pactl
}

@test "function_detect_sound_pulseaudio_via_pipewire" {
    function pgrep() {
        echo "pulse"
    }
    function command() {
        return 1
    }
    export -f pgrep command
    detect_sound
    assert_equal "$SOUND_SERVER" "PulseAudio (on PipeWire)"
    unset pgrep command
}

@test "function_detect_sound_pulseaudio_wsl2" {
    PULSE_SOCKET_WSL2=/tmp/PulseServer
    run touch "$PULSE_SOCKET_WSL2"
    function pactl() {
        echo "Server Name: pulseaudio"
    }
    export -f pactl
    detect_sound
    assert_equal "$SOUND_SERVER" "pulseaudio"
    unset pactl
}

@test "function_detect_sound_pipewire" {
    function pgrep() {
        echo "pipewire"
    }
    export -f pgrep
    detect_sound
    assert_equal "$SOUND_SERVER" "PipeWire"
    unset pgrep
}

@test "function_detect_sound_no_audio" {
    skip "Complex sound server detection mocking"
}

function teardown() {
    rm -f "$LOG_FILE" "$PULSE_SOCKET_WSL2"
}

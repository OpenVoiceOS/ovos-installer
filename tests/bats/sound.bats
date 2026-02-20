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
    DETECT_SOUND_BACKUP=""
    if [ -f "utils/detect_sound.py" ]; then
        DETECT_SOUND_BACKUP="$(mktemp)"
        cp "utils/detect_sound.py" "$DETECT_SOUND_BACKUP"
    fi
}

@test "function_detect_sound_pulseaudio" {
    function python3() {
        if [[ "$1" == *"detect_sound.py"* ]]; then
             echo "PulseAudio"
        fi
    }
    export -f python3

    # Mock existence of the helper script
    touch "utils/detect_sound.py"

    detect_sound
    assert_equal "$SOUND_SERVER" "PulseAudio"

    rm -f "utils/detect_sound.py"
    unset python3
}

@test "function_detect_sound_pipewire" {
    function python3() {
        if [[ "$1" == *"detect_sound.py"* ]]; then
             echo "PipeWire"
        fi
    }
    export -f python3

    # Needs the python script check to pass
    touch "utils/detect_sound.py"

    detect_sound
    assert_equal "$SOUND_SERVER" "PipeWire"

    rm -f "utils/detect_sound.py"
    unset python3
}

@test "function_detect_sound_no_audio" {
    function python3() {
        echo "N/A"
    }
    export -f python3
    touch "utils/detect_sound.py"

    detect_sound
    assert_equal "$SOUND_SERVER" "N/A"

    rm -f "utils/detect_sound.py"
    unset python3
}

@test "function_detect_sound_coreaudio" {
    function python3() {
        if [[ "$1" == *"detect_sound.py"* ]]; then
             echo "CoreAudio"
        fi
    }
    export -f python3

    touch "utils/detect_sound.py"

    detect_sound
    assert_equal "$SOUND_SERVER" "CoreAudio"

    rm -f "utils/detect_sound.py"
    unset python3
}

function teardown() {
    rm -f "$LOG_FILE"
    if [ -n "$DETECT_SOUND_BACKUP" ]; then
        cp "$DETECT_SOUND_BACKUP" "utils/detect_sound.py"
        rm -f "$DETECT_SOUND_BACKUP"
    else
        rm -f "utils/detect_sound.py"
    fi
}

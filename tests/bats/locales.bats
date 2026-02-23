#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
}

@test "locales_detection_scripts_are_sourceable" {
    for f in tui/locales/*/detection.sh; do
        run bash -euc "
            DISTRO_NAME=debian
            DISTRO_VERSION='Debian 12'
            DISTRO_LABEL='macOS 15.7.2'
            KERNEL='6.0.0'
            RASPBERRYPI_MODEL='N/A'
            PYTHON='3.11'
            CPU_IS_CAPABLE='true'
            HARDWARE_DETECTED='N/A'
            VENV_PATH='/tmp/venv'
            SOUND_SERVER='PipeWire'
            DISPLAY_SERVER='wayland'
            source '$f'
            printf '%s\n' \"\$CONTENT\"
        "

        if [ "$status" -ne 0 ]; then
            echo \"Failed to source $f\" >&2
            echo \"$output\" >&2
            return 1
        fi
        assert_output --partial "macOS 15.7.2"
    done
}

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

@test "locales_llm_scripts_are_sourceable" {
    for f in tui/locales/*/llm.sh; do
        run bash -euc "
            source '$f'
            test -n \"\$LLM_TITLE_SETUP\"
            test -n \"\$LLM_TITLE_EXISTING\"
            test -n \"\$LLM_CONTENT_HAVE_DETAILS\"
            test -n \"\$LLM_CONTENT_EXISTING\"
            test -n \"\$LLM_TITLE_URL\"
            test -n \"\$LLM_CONTENT_URL\"
            test -n \"\$LLM_TITLE_KEY\"
            test -n \"\$LLM_CONTENT_KEY\"
            test -n \"\$LLM_CONTENT_KEY_KEEP_EXISTING\"
            test -n \"\$LLM_TITLE_MODEL\"
            test -n \"\$LLM_CONTENT_MODEL\"
            test -n \"\$LLM_TITLE_PERSONA\"
            test -n \"\$LLM_CONTENT_PERSONA\"
            test -n \"\$LLM_TITLE_INVALID\"
            test -n \"\$LLM_CONTENT_MISSING_INFO\"
            test -n \"\$LLM_CONTENT_INVALID_URL\"
            printf '%s\n' \"\$LLM_TITLE_SETUP\"
        "

        if [ "$status" -ne 0 ]; then
            echo \"Failed to source $f\" >&2
            echo \"$output\" >&2
            return 1
        fi
        assert_output --partial "LLM"
    done
}

@test "locales_llm_model_strings_are_localized_outside_en_us" {
    for f in tui/locales/*/llm.sh; do
        if [ "$f" = "tui/locales/en-us/llm.sh" ]; then
            continue
        fi

        run grep -F -q 'LLM_TITLE_MODEL="Open Voice OS Installation - LLM Model"' "$f"
        assert_failure

        run grep -F -q "Please enter the LLM model name to use." "$f"
        assert_failure
    done
}

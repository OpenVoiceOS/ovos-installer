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
            test -n \"\$LLM_DEFAULT_PERSONA\"
            test -n \"\$LLM_CONTENT_PERSONA\"
            test -n \"\$LLM_TITLE_MAX_TOKENS\"
            test -n \"\$LLM_CONTENT_MAX_TOKENS\"
            test -n \"\$LLM_TITLE_TEMPERATURE\"
            test -n \"\$LLM_CONTENT_TEMPERATURE\"
            test -n \"\$LLM_TITLE_TOP_P\"
            test -n \"\$LLM_CONTENT_TOP_P\"
            test -n \"\$LLM_TITLE_INVALID\"
            test -n \"\$LLM_CONTENT_MISSING_INFO\"
            test -n \"\$LLM_CONTENT_INVALID_URL\"
            test -n \"\$LLM_CONTENT_INVALID_MAX_TOKENS\"
            test -n \"\$LLM_CONTENT_INVALID_TEMPERATURE\"
            test -n \"\$LLM_CONTENT_INVALID_TOP_P\"
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

@test "locales_features_scripts_are_sourceable" {
    for f in tui/locales/*/features.sh; do
        run bash -euc "
            source '$f'
            test -n \"\$TITLE\"
            test -n \"\$CONTENT\"
            test -n \"\$SKILL_DESCRIPTION\"
            test -n \"\$EXTRA_SKILL_DESCRIPTION\"
            test -n \"\$HOMEASSISTANT_DESCRIPTION\"
            test -n \"\$LLM_DESCRIPTION\"
            printf '%s\n' \"\$TITLE\"
        "

        if [ "$status" -ne 0 ]; then
            echo \"Failed to source $f\" >&2
            echo \"$output\" >&2
            return 1
        fi
        [ -n "$output" ]
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

        run grep -F -q "LLM_DEFAULT_PERSONA=\"Respond in the same language as the user in a plain spoken style for a voice assistant." "$f"
        assert_failure
    done
}

@test "locales_feature_strings_are_localized_outside_en_us" {
    for f in tui/locales/*/features.sh; do
        if [ "$f" = "tui/locales/en-us/features.sh" ]; then
            continue
        fi

        run grep -F -q 'LLM_DESCRIPTION="Enable AI conversation fallback for OVOS Persona (guided setup for URL, key, model, style, and reply tuning)"' "$f"
        assert_failure

        run grep -F -q 'HOMEASSISTANT_DESCRIPTION="Enable Home Assistant integration (requires URL + token)"' "$f"
        assert_failure
    done
}

@test "english_llm_locale_explains reply tuning in plain language" {
    local file="tui/locales/en-us/llm.sh"

    run grep -F -q "This lets OVOS use an AI assistant when normal skills do not have a good answer." "$file"
    assert_success

    run grep -F -q "API URL: where OVOS sends AI requests" "$file"
    assert_success

    run grep -F -q "Reply length: how much room the model gets to answer" "$file"
    assert_success

    run grep -F -q "Creativity: lower is safer, higher is more imaginative" "$file"
    assert_success

    run grep -F -q "Focus: lower keeps answers tighter and more predictable" "$file"
    assert_success

    run grep -F -q "Recommended for voice use: 300" "$file"
    assert_success

    run grep -F -q "Recommended for voice use: 0.2" "$file"
    assert_success

    run grep -F -q "Recommended for voice use: 0.1" "$file"
    assert_success
}

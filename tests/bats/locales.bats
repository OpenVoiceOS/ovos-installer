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

@test "locales_summary_scripts_are_sourceable" {
    for f in tui/locales/*/summary.sh; do
        run bash -euc "
            METHOD='virtualenv'
            CHANNEL='alpha'
            PROFILE='ovos'
            FEATURE_SKILLS_SUMMARY_STATE='enabled'
            FEATURE_EXTRA_SKILLS_SUMMARY_STATE='disabled'
            HOMEASSISTANT_SUMMARY_STATE='enabled'
            LLM_SUMMARY_STATE='enabled'
            TUNING_SUMMARY_STATE='enabled'
            BACK_BUTTON='Back'
            source '$f'
            test -n \"\$TITLE\"
            test -n \"\$CONTENT\"
            printf '%s\n' \"\$CONTENT\"
        "

        if [ "$status" -ne 0 ]; then
            echo \"Failed to source $f\" >&2
            echo \"$output\" >&2
            return 1
        fi

        assert_output --partial "virtualenv"
    done
}

@test "locales_llm_model_strings_are_localized_outside_en_us" {
    for f in tui/locales/*/llm.sh; do
        if [ "$f" = "tui/locales/en-us/llm.sh" ]; then
            continue
        fi

        run bash -euc "
            source tui/locales/en-us/llm.sh
            en_title_model=\$LLM_TITLE_MODEL
            en_content_model=\$LLM_CONTENT_MODEL
            en_default_persona=\$LLM_DEFAULT_PERSONA
            source '$f'
            [ \"\$LLM_TITLE_MODEL\" != \"\$en_title_model\" ]
            [ \"\$LLM_CONTENT_MODEL\" != \"\$en_content_model\" ]
            [ \"\$LLM_DEFAULT_PERSONA\" != \"\$en_default_persona\" ]
        "
        assert_success
    done
}

@test "locales_feature_strings_are_localized_outside_en_us" {
    for f in tui/locales/*/features.sh; do
        if [ "$f" = "tui/locales/en-us/features.sh" ]; then
            continue
        fi

        run bash -euc "
            source tui/locales/en-us/features.sh
            en_llm_description=\$LLM_DESCRIPTION
            en_homeassistant_description=\$HOMEASSISTANT_DESCRIPTION
            source '$f'
            [ \"\$LLM_DESCRIPTION\" != \"\$en_llm_description\" ]
            [ \"\$HOMEASSISTANT_DESCRIPTION\" != \"\$en_homeassistant_description\" ]
        "
        assert_success
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

@test "hindi_llm_locale_avoids leftover English UI terms" {
    local file="tui/locales/hi-in/llm.sh"

    run grep -Eq '\b(default|provider|summary|voice-friendly|tuning)\b' "$file"
    assert_failure
}

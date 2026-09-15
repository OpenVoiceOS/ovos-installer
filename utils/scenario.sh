#!/usr/bin/env bash
set -euo pipefail

# Safe defaults for strict mode
: "${SCENARIO_PATH:=}"
: "${YQ_BINARY_PATH:=yq}"

# Record why the scenario was refused. Every rejection below sets
# SCENARIO_NOT_SUPPORTED, and without this the installer can only report
# "scenario not supported" with no clue which line to edit.
function scenario_reject() {
    local key="$1" value="$2" expected="${3:-}"
    export SCENARIO_NOT_SUPPORTED="true"
    SCENARIO_ERROR="$key: ${value:-<empty>}"
    if [ -n "$expected" ]; then
        SCENARIO_ERROR="$SCENARIO_ERROR (expected: $expected)"
    fi
    export SCENARIO_ERROR
}

if [ -f "$SCENARIO_PATH" ]; then
    # Variables to store options, features and hivemind content
    declare -A options
    declare -A features
    declare -A hivemind
    declare -A llm
    declare -a required_options=(
        uninstall
        method
        channel
        profile
        features
        raspberry_pi_tuning
        share_telemetry
        share_usage_telemetry
    )

    # Read all the options
    while IFS="=" read -r key_option value_option; do
        case "$key_option" in
        rapsberry_pi_tuning | raspeberry_pi_tuning)
            key_option="raspberry_pi_tuning"
            ;;
        esac
        options["$key_option"]="$value_option"
    done < <(
        "$YQ_BINARY_PATH" 'to_entries | map([.key, .value] | join("=")) | .[]' "$SCENARIO_PATH"
    )

    # Read all the features
    while IFS="=" read -r key_feature value_feature; do
        features["$key_feature"]="$value_feature"
    done < <(
        "$YQ_BINARY_PATH" '.features | to_entries | map([.key, .value] | join("=")) | .[]' "$SCENARIO_PATH"
    )

    # Read all the hivemind options
    while IFS="=" read -r key_hivemind value_hivemind; do
        hivemind["$key_hivemind"]="$value_hivemind"
    done < <(
        "$YQ_BINARY_PATH" '.hivemind | to_entries | map([.key, .value] | join("=")) | .[]' "$SCENARIO_PATH"
    )

    # Read all the llm options
    while IFS="=" read -r key_llm value_llm; do
        llm["$key_llm"]="$value_llm"
    done < <(
        "$YQ_BINARY_PATH" '.llm | to_entries | map([.key, .value] | join("=")) | .[]' "$SCENARIO_PATH"
    )

    # Make sure the scenario file is not empty
    if [ -z "${!options[*]}" ]; then
        export SCENARIO_NOT_SUPPORTED="true"
    fi

    # Required options must always be present.
    for required_option in "${required_options[@]}"; do
        if [ -z "${options[$required_option]+x}" ]; then
            export SCENARIO_NOT_SUPPORTED="true"
        fi
    done

    # Loop over each options and features
    for option in "${!options[@]}"; do
        # Ensure the option is supported by the installer
        if in_array SCENARIO_ALLOWED_OPTIONS "$option"; then
            case "$option" in
            uninstall)
                if [[ "${options[$option]}" == "true" ]]; then
                    UNINSTALL="true"
                elif [[ "${options[$option]}" == "false" ]]; then
                    UNINSTALL="false"
                else
                    scenario_reject "uninstall" "${options[$option]}" "true, false"
                    break
                fi
                export UNINSTALL
                ;;
            method)
                if [[ "${options[$option]}" == "containers" ]]; then
                    METHOD="containers"
                elif [[ "${options[$option]}" == "virtualenv" ]]; then
                    METHOD="virtualenv"
                else
                    scenario_reject "method" "${options[$option]}" "containers, virtualenv"
                    break
                fi
                export METHOD
                ;;
            channel)
                if [[ "${options[$option]}" == "testing" ]]; then
                    CHANNEL="testing"
                elif [[ "${options[$option]}" == "alpha" ]]; then
                    CHANNEL="alpha"
                else
                    scenario_reject "channel" "${options[$option]}" "testing, alpha"
                    break
                fi
                export CHANNEL
                ;;
            profile)
                if [[ "${options[$option]}" == "ovos" ]]; then
                    PROFILE="ovos"
                elif [[ "${options[$option]}" == "satellite" ]]; then
                    PROFILE="satellite"
                elif [[ "${options[$option]}" == "listener" ]]; then
                    PROFILE="listener"
                elif [[ "${options[$option]}" == "server" ]]; then
                    PROFILE="server"
                else
                    scenario_reject "profile" "${options[$option]}" "ovos, satellite, listener, server"
                    break
                fi
                export PROFILE
                ;;
            hardware)
                case "${options[$option]}" in
                generic | mark2 | devkit)
                    export HARDWARE_CONFIRMATION="${options[$option]}"
                    ;;
                *)
                    export SCENARIO_NOT_SUPPORTED="true"
                    break
                    ;;
                esac
                ;;
            raspberry_pi_tuning)
                if [[ "${options[$option]}" == "true" ]]; then
                    TUNING="yes"
                elif [[ "${options[$option]}" == "false" ]]; then
                    TUNING="no"
                else
                    scenario_reject "raspberry_pi_tuning" "${options[$option]}" "true, false"
                    break
                fi
                export TUNING
                ;;
            features)
                for feature in "${!features[@]}"; do
                    # Ensure the feature is supported by the installer
                    if in_array SCENARIO_ALLOWED_FEATURES "$feature"; then
                        case "$feature" in
                        skills)
                            if [[ "${features[$feature]}" == "true" ]]; then
                                FEATURE_SKILLS="true"
                            elif [[ "${features[$feature]}" == "false" ]]; then
                                FEATURE_SKILLS="false"
                            else
                                scenario_reject "skills" "${features[$feature]}" "true, false"
                                break
                            fi
                            export FEATURE_SKILLS
                            ;;
                        extra_skills)
                            if [[ "${features[$feature]}" == "true" ]]; then
                                FEATURE_EXTRA_SKILLS="true"
                            elif [[ "${features[$feature]}" == "false" ]]; then
                                FEATURE_EXTRA_SKILLS="false"
                            else
                                scenario_reject "extra_skills" "${features[$feature]}" "true, false"
                                break
                            fi
                            export FEATURE_EXTRA_SKILLS
                            ;;
                        gui)
                            if [[ "${features[$feature]}" == "true" ]]; then
                                FEATURE_GUI="true"
                            elif [[ "${features[$feature]}" == "false" ]]; then
                                FEATURE_GUI="false"
                            else
                                scenario_reject "gui" "${features[$feature]}" "true, false"
                                break
                            fi
                            export FEATURE_GUI
                            ;;
                        homeassistant)
                            if [[ "${features[$feature]}" == "true" ]]; then
                                FEATURE_HOMEASSISTANT="true"
                            elif [[ "${features[$feature]}" == "false" ]]; then
                                FEATURE_HOMEASSISTANT="false"
                            else
                                scenario_reject "homeassistant" "${features[$feature]}" "true, false"
                                break
                            fi
                            export FEATURE_HOMEASSISTANT
                            ;;
                        llm)
                            if [[ "${features[$feature]}" == "true" ]]; then
                                FEATURE_LLM="true"
                            elif [[ "${features[$feature]}" == "false" ]]; then
                                FEATURE_LLM="false"
                            else
                                scenario_reject "llm" "${features[$feature]}" "true, false"
                                break
                            fi
                            export FEATURE_LLM
                            ;;
                        *)
                            export SCENARIO_NOT_SUPPORTED="true"
                            ;;
                        esac
                    fi
                done
                ;;
            hivemind)
                for hivemind_option in "${!hivemind[@]}"; do
                    # Ensure the hivemind option is supported by the installer
                    if in_array SCENARIO_ALLOWED_HIVEMIND_OPTIONS "$hivemind_option"; then
                        case "$hivemind_option" in
                        host)
                            [ -n "${hivemind[$hivemind_option]}" ] && export HIVEMIND_HOST="${hivemind[$hivemind_option]}"
                            ;;
                        port)
                            [ -n "${hivemind[$hivemind_option]}" ] && export HIVEMIND_PORT="${hivemind[$hivemind_option]}"
                            ;;
                        key)
                            [ -n "${hivemind[$hivemind_option]}" ] && export SATELLITE_KEY="${hivemind[$hivemind_option]}"
                            ;;
                        password)
                            [ -n "${hivemind[$hivemind_option]}" ] && export SATELLITE_PASSWORD="${hivemind[$hivemind_option]}"
                            ;;
                        *)
                            export SCENARIO_NOT_SUPPORTED="true"
                            ;;
                        esac
                    fi
                done
                ;;
            llm)
                for llm_option in "${!llm[@]}"; do
                    # Ensure the llm option is supported by the installer
                    if in_array SCENARIO_ALLOWED_LLM_OPTIONS "$llm_option"; then
                        case "$llm_option" in
                        api_url)
                            export LLM_API_URL="${llm[$llm_option]}"
                            ;;
                        key)
                            export LLM_API_KEY="${llm[$llm_option]}"
                            ;;
                        model)
                            export LLM_MODEL="${llm[$llm_option]}"
                            ;;
                        persona)
                            export LLM_PERSONA="${llm[$llm_option]}"
                            ;;
                        max_tokens)
                            export LLM_MAX_TOKENS="${llm[$llm_option]}"
                            ;;
                        temperature)
                            export LLM_TEMPERATURE="${llm[$llm_option]}"
                            ;;
                        top_p)
                            export LLM_TOP_P="${llm[$llm_option]}"
                            ;;
                        *)
                            export SCENARIO_NOT_SUPPORTED="true"
                            ;;
                        esac
                    fi
                done
                ;;
            share_telemetry)
                if [[ "${options[$option]}" == "true" ]]; then
                    SHARE_TELEMETRY="true"
                elif [[ "${options[$option]}" == "false" ]]; then
                    SHARE_TELEMETRY="false"
                else
                    scenario_reject "share_telemetry" "${options[$option]}" "true, false"
                    break
                fi
                export SHARE_TELEMETRY
                ;;
            share_usage_telemetry)
                if [[ "${options[$option]}" == "true" ]]; then
                    SHARE_USAGE_TELEMETRY="true"
                elif [[ "${options[$option]}" == "false" ]]; then
                    SHARE_USAGE_TELEMETRY="false"
                else
                    scenario_reject "share_usage_telemetry" "${options[$option]}" "true, false"
                    break
                fi
                export SHARE_USAGE_TELEMETRY
                ;;
            *)
                export SCENARIO_NOT_SUPPORTED="true"
                ;;
            esac
        fi
    done
fi

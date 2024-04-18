#!/usr/bin/env bash

if [ -f "$SCENARIO_PATH" ]; then
    # Variables to store options, features and hivemind content
    declare -A options
    declare -A features
    declare -A hivemind

    # Read all the options
    while IFS="=" read -r key_option value_option; do
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

    # Make sure the scenario file is not empty
    if [ -z "${!options[*]}" ]; then
        export SCENARIO_NOT_SUPPORTED="true"
    elif [ "${#options[@]}" -lt 7 ]; then
        export SCENARIO_NOT_SUPPORTED="true"
    fi

    # Loop over each options and features
    for option in "${!options[@]}"; do
        # Ensure the option is supported by the installer
        if in_array SCENARIO_ALLOWED_OPTIONS "$option"; then
            case "$option" in
            uninstall)
                [ "${options[$option]}" == "true" ] && CONFIRM_UNINSTALL="true" || CONFIRM_UNINSTALL="false"
                export CONFIRM_UNINSTALL
                ;;
            method)
                [ "${options[$option]}" == "containers" ] && METHOD="containers" || METHOD="virtualenv"
                export METHOD
                ;;
            channel)
                [ "${options[$option]}" == "development" ] && CHANNEL="development" || CHANNEL="stable"
                export CHANNEL
                ;;
            profile)
                [ -n "${options[$option]}" ] && export PROFILE="${options[$option]}"
                ;;
            rapsberry_pi_tuning)
                [ "${options[$option]}" == "true" ] && TUNING="yes" || TUNING="no"
                export TUNING
                ;;
            features)
                for feature in "${!features[@]}"; do
                    # Ensure the feature is supported by the installer
                    if in_array SCENARIO_ALLOWED_FEATURES "$feature"; then
                        case "$feature" in
                        skills)
                            [ "${features[$feature]}" == "true" ] && FEATURE_SKILLS="true" || FEATURE_SKILLS="false"
                            export FEATURE_SKILLS
                            ;;
                        gui)
                            [ "${features[$feature]}" == "true" ] && FEATURE_GUI="true" || FEATURE_GUI="false"
                            export FEATURE_GUI
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
            share_telemetry)
                [ "${options[$option]}" == "true" ] && SHARE_TELEMETRY="true" || SHARE_TELEMETRY="false"
                export SHARE_TELEMETRY
                ;;
            *)
                export SCENARIO_NOT_SUPPORTED="true"
                ;;
            esac
        fi
    done
fi

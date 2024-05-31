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
                if [[ "${options[$option]}" == "true" ]]; then
                    UNINSTALL="true"
                elif [[ "${options[$option]}" == "false" ]]; then
                    UNINSTALL="false"
                else
                    export SCENARIO_NOT_SUPPORTED="true"
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
                    export SCENARIO_NOT_SUPPORTED="true"
                    break
                fi
                export METHOD
                ;;
            channel)
                if [[ "${options[$option]}" == "development" ]]; then
                    CHANNEL="development"
                elif [[ "${options[$option]}" == "stable" ]]; then
                    CHANNEL="stable"
                else
                    export SCENARIO_NOT_SUPPORTED="true"
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
                    export SCENARIO_NOT_SUPPORTED="true"
                    break
                fi
                export PROFILE
                ;;
            rapsberry_pi_tuning)
                if [[ "${options[$option]}" == "true" ]]; then
                    TUNING="yes"
                elif [[ "${options[$option]}" == "false" ]]; then
                    TUNING="no"
                else
                    export SCENARIO_NOT_SUPPORTED="true"
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
                                export SCENARIO_NOT_SUPPORTED="true"
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
                                export SCENARIO_NOT_SUPPORTED="true"
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
                                export SCENARIO_NOT_SUPPORTED="true"
                                break
                            fi
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
                if [[ "${options[$option]}" == "true" ]]; then
                    SHARE_TELEMETRY="true"
                elif [[ "${options[$option]}" == "false" ]]; then
                    SHARE_TELEMETRY="false"
                else
                    export SCENARIO_NOT_SUPPORTED="true"
                    break
                fi
                export SHARE_TELEMETRY
                ;;
            *)
                export SCENARIO_NOT_SUPPORTED="true"
                ;;
            esac
        fi
    done
fi

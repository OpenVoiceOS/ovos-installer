#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    load ../../utils/constants.sh

    # TUI defaults used by the scripts
    export LOCALE="en-us"
    # shellcheck source=tui/locales/en-us/misc.sh
    source tui/locales/en-us/misc.sh

    LOG_FILE="$(mktemp)"
    INSTALLER_STATE_FILE="$(mktemp)"
    rm -f "$INSTALLER_STATE_FILE"
    WHIPTAIL_SPY_FILE="$(mktemp)"
    WHIPTAIL_DIALOG_FILE="$(mktemp)"
    WHIPTAIL_INPUT_QUEUE_FILE="$(mktemp)"
    RUN_AS_HOME="$(mktemp -d)"

    export EXISTING_INSTANCE="false"
    export ARCH="x86_64"
    export RASPBERRYPI_MODEL="N/A"
    export DISTRO_NAME="ubuntu"
    DETECTED_DEVICES=()

    # Whiptail spy values (written from subshells via $WHIPTAIL_SPY_FILE)
    WHIPTAIL_FORCE_SELECTION=""
    WHIPTAIL_FORCE_YESNO_STATUS="0"
    printf '%s\n' "list_height=0" "option_count=0" "tags=" >"$WHIPTAIL_SPY_FILE"
    : >"$WHIPTAIL_DIALOG_FILE"
    : >"$WHIPTAIL_INPUT_QUEUE_FILE"

    # Minimal whiptail stub that validates list arguments and returns a selection.
    whiptail() {
        local args=("$@")
        local j k
        local dialog_type=""
        local dialog_title=""

        for ((j = 0; j < ${#args[@]}; j++)); do
            case "${args[$j]}" in
                --inputbox|--passwordbox|--yesno|--msgbox|--checklist|--radiolist)
                    dialog_type="${args[$j]}"
                    ;;
                --title)
                    dialog_title="${args[$((j + 1))]}"
                    ;;
            esac
        done

        case "$dialog_type" in
            --inputbox)
                local default_value="${args[$(( ${#args[@]} - 1 ))]}"
                local response="$default_value"
                if whiptail_queue_has_response; then
                    response="$(whiptail_dequeue_response)"
                fi
                case "$response" in
                    __DEFAULT__)
                        response="$default_value"
                        ;;
                    __EMPTY__)
                        response=""
                        ;;
                esac
                printf '%s\t%s\t%s\t%s\t%s\n' "inputbox" "$dialog_title" "$default_value" "$response" "0" >>"$WHIPTAIL_DIALOG_FILE"
                printf '%s\n' "$response" >&2
                return 0
                ;;
            --passwordbox)
                local response=""
                if whiptail_queue_has_response; then
                    response="$(whiptail_dequeue_response)"
                fi
                case "$response" in
                    __EMPTY__)
                        response=""
                        ;;
                esac
                printf '%s\t%s\t%s\t%s\t%s\n' "passwordbox" "$dialog_title" "" "<redacted>" "0" >>"$WHIPTAIL_DIALOG_FILE"
                printf '%s\n' "$response" >&2
                return 0
                ;;
            --yesno)
                printf '%s\t%s\t%s\t%s\t%s\n' "yesno" "$dialog_title" "" "" "$WHIPTAIL_FORCE_YESNO_STATUS" >>"$WHIPTAIL_DIALOG_FILE"
                return "$WHIPTAIL_FORCE_YESNO_STATUS"
                ;;
            --msgbox)
                local dialog_body="${args[$(( ${#args[@]} - 3 ))]}"
                dialog_body="${dialog_body//$'\n'/\\n}"
                printf '%s\t%s\t%s\t%s\t%s\n' "msgbox" "$dialog_title" "" "$dialog_body" "0" >>"$WHIPTAIL_DIALOG_FILE"
                return 0
                ;;
        esac

        # Find the "height width list-height" triple that precedes (tag item status)*.
        for ((j = 0; j + 5 < ${#args[@]}; j++)); do
            if [[ "${args[$j]}" =~ ^[0-9]+$ && "${args[$((j + 1))]}" =~ ^[0-9]+$ && "${args[$((j + 2))]}" =~ ^[0-9]+$ ]]; then
                local options_start=$((j + 3))
                local remaining=$(( ${#args[@]} - options_start ))

                if (( remaining >= 3 && remaining % 3 == 0 )); then
                    # Validate status fields and collect tags.
                    local -a parsed_tags=()
                    local -a parsed_statuses=()
                    for ((k = options_start; k < ${#args[@]}; k += 3)); do
                        local tag="${args[$k]}"
                        local status="${args[$((k + 2))]}"

                        # Tag must be non-empty to avoid blank lists.
                        if [ -z "$tag" ]; then
                            echo "whiptail: empty tag detected" >&2
                            return 2
                        fi

                        case "$status" in
                            on|off|ON|OFF) ;;
                            *)
                                echo "whiptail: invalid status '$status'" >&2
                                return 2
                                ;;
                        esac

                        parsed_tags+=("$tag")
                        parsed_statuses+=("${status^^}")
                    done

                    local parsed_list_height="${args[$((j + 2))]}"
                    local parsed_option_count="$(( remaining / 3 ))"

                    if [ "$parsed_list_height" -lt 1 ]; then
                        echo "whiptail: list-height must be >= 1" >&2
                        return 2
                    fi

                    # Persist parsed args to a file because whiptail is called in a subshell.
                    {
                        printf 'list_height=%s\n' "$parsed_list_height"
                        printf 'option_count=%s\n' "$parsed_option_count"
                        printf 'tags=%s\n' "${parsed_tags[*]}"
                        printf 'statuses=%s\n' "${parsed_statuses[*]}"
                    } >"$WHIPTAIL_SPY_FILE"

                    local selection="${WHIPTAIL_FORCE_SELECTION:-${parsed_tags[0]}}"
                    printf '%s\n' "$selection" >&2
                    return 0
                fi
            fi
        done

        # Non-list dialogs: succeed with no output.
        return 0
    }
    export -f whiptail whiptail_queue_has_response whiptail_dequeue_response
}

function spy_value() {
    local key="$1"
    awk -F= -v k="$key" '$1==k {print $2; exit}' "$WHIPTAIL_SPY_FILE"
}

function whiptail_queue_has_response() {
    [ -s "$WHIPTAIL_INPUT_QUEUE_FILE" ]
}

function whiptail_dequeue_response() {
    local response
    local queue_tmp

    response="$(sed -n '1p' "$WHIPTAIL_INPUT_QUEUE_FILE")"
    queue_tmp="$(mktemp)"
    sed '1d' "$WHIPTAIL_INPUT_QUEUE_FILE" >"$queue_tmp"
    mv -f "$queue_tmp" "$WHIPTAIL_INPUT_QUEUE_FILE"
    printf '%s' "$response"
}

function queue_whiptail_response() {
    printf '%s\n' "$1" >>"$WHIPTAIL_INPUT_QUEUE_FILE"
}

function dialog_value() {
    local dialog_kind="$1"
    local dialog_title="$2"
    local field="$3"
    local column=0

    case "$field" in
        default)
            column=3
            ;;
        response)
            column=4
            ;;
        status)
            column=5
            ;;
        *)
            echo "unsupported dialog field: $field" >&2
            return 1
            ;;
    esac

    awk -F '\t' -v kind="$dialog_kind" -v title="$dialog_title" -v col="$column" '
        $1 == kind && $2 == title {value = $col}
        END {
            gsub(/\\n/, "\n", value)
            print value
        }
    ' "$WHIPTAIL_DIALOG_FILE"
}

@test "channels: shows all options when navigating back in a new install" {
    printf '%s\n' '{"channel":"testing"}' >"$INSTALLER_STATE_FILE"
    EXISTING_INSTANCE="false"
    WHIPTAIL_FORCE_SELECTION="testing"

    # shellcheck source=tui/channels.sh
    source tui/channels.sh

    assert_equal "$(spy_value option_count)" "2"
    assert_equal "$(spy_value list_height)" "4"
}

@test "channels: locks selection for an existing install" {
    printf '%s\n' '{"channel":"testing"}' >"$INSTALLER_STATE_FILE"
    EXISTING_INSTANCE="true"
    WHIPTAIL_FORCE_SELECTION="testing"

    # shellcheck source=tui/channels.sh
    source tui/channels.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
}

@test "channels: hides non-alpha channels on Mark 2/DevKit hardware" {
    EXISTING_INSTANCE="false"
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION="alpha"

    # shellcheck source=tui/channels.sh
    source tui/channels.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "alpha"
}

@test "telemetry: declining prompt keeps installer flow alive and disables telemetry" {
    WHIPTAIL_FORCE_YESNO_STATUS="1"

    # shellcheck source=tui/telemetry.sh
    source tui/telemetry.sh

    assert_equal "$SHARE_TELEMETRY" "false"
}

@test "usage telemetry: declining prompt keeps installer flow alive and disables usage telemetry" {
    WHIPTAIL_FORCE_YESNO_STATUS="1"

    # shellcheck source=tui/usage_telemetry.sh
    source tui/usage_telemetry.sh

    assert_equal "$SHARE_USAGE_TELEMETRY" "false"
}

@test "profiles: shows all options when navigating back in a new install" {
    printf '%s\n' '{"profile":"ovos"}' >"$INSTALLER_STATE_FILE"
    EXISTING_INSTANCE="false"
    WHIPTAIL_FORCE_SELECTION="ovos"

    # shellcheck source=tui/profiles.sh
    source tui/profiles.sh

    assert_equal "$(spy_value option_count)" "4"
    assert_equal "$(spy_value list_height)" "4"
}

@test "profiles: locks selection for an existing install" {
    printf '%s\n' '{"profile":"ovos"}' >"$INSTALLER_STATE_FILE"
    EXISTING_INSTANCE="true"
    WHIPTAIL_FORCE_SELECTION="ovos"

    # shellcheck source=tui/profiles.sh
    source tui/profiles.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
}

@test "methods: never renders an empty radiolist (guards invalid INSTANCE_TYPE)" {
    EXISTING_INSTANCE="true"
    INSTANCE_TYPE="not-a-method"
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    # On x86_64 with no other restrictions, both methods are available.
    assert_equal "$(spy_value option_count)" "2"
    assert_equal "$(spy_value list_height)" "4"
}

@test "methods: hides containers on macOS" {
    DISTRO_NAME="macos"
    EXISTING_INSTANCE="false"
    INSTANCE_TYPE=""
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "virtualenv"
}

@test "methods: keeps containers hidden on macOS for existing container installs" {
    DISTRO_NAME="macos"
    EXISTING_INSTANCE="true"
    INSTANCE_TYPE="containers"
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "virtualenv"
}

@test "methods: hides containers on Mark 2 hardware" {
    EXISTING_INSTANCE="false"
    INSTANCE_TYPE=""
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "virtualenv"
}

@test "methods: keeps containers hidden on Mark 2 for existing container installs" {
    EXISTING_INSTANCE="true"
    INSTANCE_TYPE="containers"
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "virtualenv"
}

@test "methods: applies Mark 2 restriction to DevKit detection" {
    EXISTING_INSTANCE="false"
    INSTANCE_TYPE=""
    DETECTED_DEVICES=("attiny1614" "tas5806")
    WHIPTAIL_FORCE_SELECTION="virtualenv"

    # shellcheck source=tui/methods.sh
    source tui/methods.sh

    assert_equal "$(spy_value option_count)" "1"
    assert_equal "$(spy_value list_height)" "4"
    assert_equal "$(spy_value tags)" "virtualenv"
}

@test "features: checklist always has non-zero list-height and options" {
    printf '%s\n' '{"profile":"ovos","channel":"testing","features":["skills"]}' >"$INSTALLER_STATE_FILE"
    PROFILE="ovos"
    WHIPTAIL_FORCE_SELECTION="skills"

    # shellcheck source=tui/features.sh
    source tui/features.sh

    assert_equal "$(spy_value option_count)" "4"
    assert_equal "$(spy_value list_height)" "4"
}

@test "features: shows GUI on Debian Trixie Mark 2 hardware and enables it when selected" {
    PROFILE="ovos"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION=$'skills\ngui'

    # shellcheck source=tui/features.sh
    source tui/features.sh

    assert_equal "$(spy_value option_count)" "5"
    tags="$(spy_value tags)"
    if [[ "$tags" != *gui* ]]; then
        echo "expected gui in tag list: $tags" >&2
        return 1
    fi
    assert_equal "$FEATURE_GUI" "true"
}

@test "features: honors persisted GUI disabled state on Debian Trixie Mark 2 hardware" {
    printf '%s\n' '{"profile":"ovos","channel":"testing","features":["skills"],"feature_gui_selected":false}' >"$INSTALLER_STATE_FILE"
    PROFILE="ovos"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION="skills"

    # shellcheck source=tui/features.sh
    source tui/features.sh

    assert_equal "$FEATURE_GUI" "false"
}

@test "features: legacy state defaults GUI to ON on Debian Trixie Mark 2 hardware" {
    printf '%s\n' '{"profile":"ovos","channel":"testing","features":["skills"]}' >"$INSTALLER_STATE_FILE"
    PROFILE="ovos"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION=$'skills\ngui'

    # shellcheck source=tui/features.sh
    source tui/features.sh

    assert_equal "$(spy_value statuses)" "ON OFF ON OFF OFF"
    assert_equal "$FEATURE_GUI" "true"
}

@test "features: invalid persisted GUI type falls back to Mark 2 default ON" {
    printf '%s\n' '{"profile":"ovos","channel":"testing","features":["skills"],"feature_gui_selected":"false"}' >"$INSTALLER_STATE_FILE"
    PROFILE="ovos"
    DISTRO_NAME="debian"
    DISTRO_VERSION_ID="13"
    DISTRO_VERSION="Debian GNU/Linux 13 (trixie)"
    DETECTED_DEVICES=("tas5806")
    WHIPTAIL_FORCE_SELECTION=$'skills\ngui'

    # shellcheck source=tui/features.sh
    source tui/features.sh

    assert_equal "$(spy_value statuses)" "ON OFF ON OFF OFF"
    assert_equal "$FEATURE_GUI" "true"
}

@test "features: shows Home Assistant option for containers installs" {
    printf '%s\n' '{"profile":"ovos","channel":"testing","features":["skills"]}' >"$INSTALLER_STATE_FILE"
    PROFILE="ovos"
    METHOD="containers"
    WHIPTAIL_FORCE_SELECTION="skills"

    # shellcheck source=tui/features.sh
    source tui/features.sh

    assert_equal "$(spy_value option_count)" "4"
    assert_equal "$(spy_value list_height)" "4"

    tags="$(spy_value tags)"
    if [[ "$tags" != *homeassistant* ]]; then
        echo "expected homeassistant in tag list: $tags" >&2
        return 1
    fi
    if [[ "$tags" != *llm* ]]; then
        echo "expected llm in tag list: $tags" >&2
        return 1
    fi
}

@test "features: selecting llm enables feature with preseeded configuration" {
    printf '%s\n' '{"profile":"ovos","channel":"testing","features":["skills"]}' >"$INSTALLER_STATE_FILE"
    PROFILE="ovos"
    METHOD="virtualenv"
    LLM_API_URL="https://llama.smartgic.io/v1"
    LLM_API_KEY="sk-test"
    LLM_MODEL="gpt-4o-mini"
    LLM_PERSONA="helpful, creative, clever, and very friendly."
    WHIPTAIL_FORCE_SELECTION=$'skills\nllm'

    # shellcheck source=tui/features.sh
    source tui/features.sh

    assert_equal "$FEATURE_LLM" "true"
}

@test "llm: guided setup persists reply tuning values" {
    METHOD="virtualenv"
    queue_whiptail_response "https://llama.smartgic.io/v1"
    queue_whiptail_response "sk-test"
    queue_whiptail_response "qwen3-nothink:latest"
    queue_whiptail_response "Respond in plain spoken English for a voice assistant. Keep replies concise."
    queue_whiptail_response "300"
    queue_whiptail_response "0.2"
    queue_whiptail_response "0.1"

    # shellcheck source=tui/llm.sh
    source tui/llm.sh

    assert_equal "$FEATURE_LLM" "true"
    assert_equal "$LLM_API_URL" "https://llama.smartgic.io/v1"
    assert_equal "$LLM_MODEL" "qwen3-nothink:latest"
    assert_equal "$LLM_MAX_TOKENS" "300"
    assert_equal "$LLM_TEMPERATURE" "0.2"
    assert_equal "$LLM_TOP_P" "0.1"

    run jq -r '"\(.llm.api_url)|\(.llm.model)|\(.llm.max_tokens|tostring)|\(.llm.temperature|tostring)|\(.llm.top_p|tostring)"' "$INSTALLER_STATE_FILE"
    assert_success
    assert_output "https://llama.smartgic.io/v1|qwen3-nothink:latest|300|0.2|0.1"

    run jq -r '"\(.llm.max_tokens|type)|\(.llm.temperature|type)|\(.llm.top_p|type)"' "$INSTALLER_STATE_FILE"
    assert_success
    assert_output "number|number|number"
}

@test "llm: invalid url shows the URL-specific validation message" {
    METHOD="virtualenv"
    queue_whiptail_response "invalid://url"
    queue_whiptail_response "https://llama.smartgic.io/v1"
    queue_whiptail_response "sk-test"
    queue_whiptail_response "qwen3-nothink:latest"
    queue_whiptail_response "Respond in plain spoken English for a voice assistant. Keep replies concise."
    queue_whiptail_response "300"
    queue_whiptail_response "0.2"
    queue_whiptail_response "0.1"

    # shellcheck source=tui/llm.sh
    source tui/llm.sh

    local invalid_message
    invalid_message="$(dialog_value msgbox "$LLM_TITLE_INVALID" response)"

    assert_equal "$FEATURE_LLM" "true"
    [[ "$invalid_message" == *"Invalid URL."* ]]
    [[ "$invalid_message" == *"Please provide a valid OpenAI-compatible API URL."* ]]
}

@test "llm: restores persisted defaults for reply tuning prompts" {
    printf '%s\n' '{"llm":{"api_url":"https://llama.smartgic.io/v1","model":"qwen3-nothink:latest","persona":"Respond briefly and clearly.","max_tokens":"450","temperature":"0.4","top_p":"0.7"}}' >"$INSTALLER_STATE_FILE"
    METHOD="virtualenv"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "sk-from-state"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"

    # shellcheck source=tui/llm.sh
    source tui/llm.sh

    assert_equal "$FEATURE_LLM" "true"
    assert_equal "$LLM_API_URL" "https://llama.smartgic.io/v1"
    assert_equal "$LLM_MODEL" "qwen3-nothink:latest"
    assert_equal "$LLM_PERSONA" "Respond briefly and clearly."
    assert_equal "$LLM_MAX_TOKENS" "450"
    assert_equal "$LLM_TEMPERATURE" "0.4"
    assert_equal "$LLM_TOP_P" "0.7"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_URL" default)" "https://llama.smartgic.io/v1"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_MODEL" default)" "qwen3-nothink:latest"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_PERSONA" default)" "Respond briefly and clearly."
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_MAX_TOKENS" default)" "450"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_TEMPERATURE" default)" "0.4"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_TOP_P" default)" "0.7"
}

@test "llm: keeping an existing persona profile also restores tuning values" {
    mkdir -p "$RUN_AS_HOME/.config/ovos_persona"
    cat <<'EOF' >"$RUN_AS_HOME/.config/ovos_persona/ovos-installer-llm.json"
{
  "name": "OVOS Installer LLM",
  "ovos-solver-openai-plugin": {
    "api_url": "https://llama.smartgic.io/v1",
    "key": "sk-existing",
    "model": "qwen3-nothink:latest",
    "system_prompt": "Respond in plain spoken English.",
    "max_tokens": 320,
    "temperature": 0.2,
    "top_p": 0.1
  },
  "solvers": [
    "ovos-solver-openai-plugin"
  ]
}
EOF
    METHOD="virtualenv"
    WHIPTAIL_FORCE_YESNO_STATUS="0"

    # shellcheck source=tui/llm.sh
    source tui/llm.sh

    assert_equal "$FEATURE_LLM" "true"
    assert_equal "$LLM_API_URL" "https://llama.smartgic.io/v1"
    assert_equal "$LLM_MODEL" "qwen3-nothink:latest"
    assert_equal "$LLM_PERSONA" "Respond in plain spoken English."
    assert_equal "$LLM_MAX_TOKENS" "320"
    assert_equal "$LLM_TEMPERATURE" "0.2"
    assert_equal "$LLM_TOP_P" "0.1"
    assert_equal "$(dialog_value yesno "$LLM_TITLE_EXISTING" status)" "0"

    run jq -r '"\(.llm.api_url)|\(.llm.model)|\(.llm.max_tokens|tostring)|\(.llm.temperature|tostring)|\(.llm.top_p|tostring)"' "$INSTALLER_STATE_FILE"
    assert_success
    assert_output "https://llama.smartgic.io/v1|qwen3-nothink:latest|320|0.2|0.1"

    run jq -r '"\(.llm.max_tokens|type)|\(.llm.temperature|type)|\(.llm.top_p|type)"' "$INSTALLER_STATE_FILE"
    assert_success
    assert_output "number|number|number"
}

@test "llm: esc on existing persona configuration goes back cleanly" {
    mkdir -p "$RUN_AS_HOME/.config/ovos_persona"
    cat <<'EOF' >"$RUN_AS_HOME/.config/ovos_persona/ovos-installer-llm.json"
{
  "name": "OVOS Installer LLM",
  "ovos-solver-openai-plugin": {
    "api_url": "https://llama.smartgic.io/v1",
    "key": "sk-existing",
    "model": "qwen3-nothink:latest",
    "system_prompt": "Respond in plain spoken English.",
    "max_tokens": 320,
    "temperature": 0.2,
    "top_p": 0.1
  },
  "solvers": [
    "ovos-solver-openai-plugin"
  ]
}
EOF
    METHOD="virtualenv"
    WHIPTAIL_FORCE_YESNO_STATUS="255"

    # shellcheck source=tui/llm.sh
    source tui/llm.sh

    assert_equal "$FEATURE_LLM" "false"
    assert_equal "$LLM_BACK" "true"
    assert_equal "$(dialog_value yesno "$LLM_TITLE_EXISTING" status)" "255"
}

@test "llm: invalid preseeded tuning values fall back to validated prompt defaults" {
    METHOD="virtualenv"
    LLM_API_URL="https://llama.smartgic.io/v1"
    LLM_API_KEY="sk-preseeded"
    LLM_MODEL="qwen3-nothink:latest"
    LLM_PERSONA="Respond briefly and clearly."
    LLM_MAX_TOKENS="not-a-number"
    LLM_TEMPERATURE="3"
    LLM_TOP_P="2"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "sk-preseeded"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"

    # shellcheck source=tui/llm.sh
    source tui/llm.sh

    assert_equal "$FEATURE_LLM" "true"
    assert_equal "$LLM_MAX_TOKENS" "300"
    assert_equal "$LLM_TEMPERATURE" "0.2"
    assert_equal "$LLM_TOP_P" "0.1"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_URL" default)" "https://llama.smartgic.io/v1"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_MAX_TOKENS" default)" "300"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_TEMPERATURE" default)" "0.2"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_TOP_P" default)" "0.1"
}

@test "llm: invalid existing tuning values skip fast keep-existing flow" {
    mkdir -p "$RUN_AS_HOME/.config/ovos_persona"
    cat <<'EOF' >"$RUN_AS_HOME/.config/ovos_persona/ovos-installer-llm.json"
{
  "name": "OVOS Installer LLM",
  "ovos-solver-openai-plugin": {
    "api_url": "https://llama.smartgic.io/v1",
    "key": "sk-existing",
    "model": "qwen3-nothink:latest",
    "system_prompt": "Respond in plain spoken English.",
    "max_tokens": "bad",
    "temperature": 3,
    "top_p": 2
  },
  "solvers": [
    "ovos-solver-openai-plugin"
  ]
}
EOF
    METHOD="virtualenv"
    WHIPTAIL_FORCE_YESNO_STATUS="0"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "sk-existing"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"

    # shellcheck source=tui/llm.sh
    source tui/llm.sh

    assert_equal "$FEATURE_LLM" "true"
    assert_equal "$LLM_MAX_TOKENS" "300"
    assert_equal "$LLM_TEMPERATURE" "0.2"
    assert_equal "$LLM_TOP_P" "0.1"
    assert_equal "$(dialog_value yesno "$LLM_TITLE_EXISTING" status)" ""
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_MAX_TOKENS" default)" "300"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_TEMPERATURE" default)" "0.2"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_TOP_P" default)" "0.1"
}

@test "llm: invalid persisted tuning defaults are sanitized before prompts" {
    printf '%s\n' '{"llm":{"api_url":"https://llama.smartgic.io/v1","model":"qwen3-nothink:latest","persona":"Respond briefly and clearly.","max_tokens":"bad","temperature":"3","top_p":"2"}}' >"$INSTALLER_STATE_FILE"
    METHOD="virtualenv"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "sk-from-state"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"
    queue_whiptail_response "__DEFAULT__"

    # shellcheck source=tui/llm.sh
    source tui/llm.sh

    assert_equal "$FEATURE_LLM" "true"
    assert_equal "$LLM_MAX_TOKENS" "300"
    assert_equal "$LLM_TEMPERATURE" "0.2"
    assert_equal "$LLM_TOP_P" "0.1"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_MAX_TOKENS" default)" "300"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_TEMPERATURE" default)" "0.2"
    assert_equal "$(dialog_value inputbox "$LLM_TITLE_TOP_P" default)" "0.1"
    assert_equal "$(dialog_value msgbox "$LLM_TITLE_INVALID" response)" ""
}

@test "tuning: radiolist is well-formed (list-height >= 1, options present)" {
    WHIPTAIL_FORCE_SELECTION="no"

    # shellcheck source=tui/locales/en-us/tuning.sh
    source tui/locales/en-us/tuning.sh
    # shellcheck source=tui/tuning.sh
    source tui/tuning.sh

    assert_equal "$(spy_value option_count)" "2"
    assert_equal "$(spy_value list_height)" "4"
}

@test "tuning: persists confirmed tuning and overclock choices to installer state" {
    WHIPTAIL_FORCE_SELECTION="yes"

    # shellcheck source=tui/locales/en-us/tuning.sh
    source tui/locales/en-us/tuning.sh
    # shellcheck source=tui/tuning.sh
    source tui/tuning.sh

    run jq -r '.tuning + ":" + .tuning_overclock' "$INSTALLER_STATE_FILE"
    assert_success
    assert_output "yes:yes"
}

@test "tuning: restores persisted tuning choice as the default radiolist selection" {
    printf '%s\n' '{"tuning":"no","tuning_overclock":"no"}' >"$INSTALLER_STATE_FILE"
    WHIPTAIL_FORCE_SELECTION="no"

    # shellcheck source=tui/locales/en-us/tuning.sh
    source tui/locales/en-us/tuning.sh
    # shellcheck source=tui/tuning.sh
    source tui/tuning.sh

    assert_equal "$(spy_value statuses)" "OFF ON"
    assert_equal "$TUNING" "no"
}

@test "tuning: restores persisted overclock choice as the default radiolist selection" {
    printf '%s\n' '{"tuning":"yes","tuning_overclock":"yes"}' >"$INSTALLER_STATE_FILE"
    WHIPTAIL_FORCE_SELECTION="yes"

    # shellcheck source=tui/locales/en-us/tuning.sh
    source tui/locales/en-us/tuning.sh
    # shellcheck source=tui/tuning.sh
    source tui/tuning.sh

    assert_equal "$(spy_value tags)" "yes no"
    assert_equal "$(spy_value statuses)" "ON OFF"
    assert_equal "$TUNING_OVERCLOCK" "yes"
}

@test "tuning: rerender after backing out of overclock uses current tuning selection" {
    local tuning_log
    local whiptail_counter
    tuning_log="$(mktemp)"
    whiptail_counter="$(mktemp)"
    printf '%s\n' "0" >"$whiptail_counter"

    whiptail() {
        local args=("$@")
        local j k
        local dialog_type=""
        local dialog_title=""
        local whiptail_invocation

        whiptail_invocation="$(cat "$whiptail_counter")"

        for ((j = 0; j < ${#args[@]}; j++)); do
            case "${args[$j]}" in
                --radiolist)
                    dialog_type="${args[$j]}"
                    ;;
                --title)
                    dialog_title="${args[$((j + 1))]}"
                    ;;
            esac
        done

        if [ "$dialog_type" != "--radiolist" ]; then
            return 0
        fi

        for ((j = 0; j + 5 < ${#args[@]}; j++)); do
            if [[ "${args[$j]}" =~ ^[0-9]+$ && "${args[$((j + 1))]}" =~ ^[0-9]+$ && "${args[$((j + 2))]}" =~ ^[0-9]+$ ]]; then
                local options_start=$((j + 3))
                local remaining=$(( ${#args[@]} - options_start ))
                if (( remaining >= 3 && remaining % 3 == 0 )); then
                    local -a parsed_statuses=()
                    for ((k = options_start; k < ${#args[@]}; k += 3)); do
                        parsed_statuses+=("${args[$((k + 2))]^^}")
                    done
                    printf '%s\t%s\t%s\n' "$whiptail_invocation" "$dialog_title" "${parsed_statuses[*]}" >>"$tuning_log"
                    break
                fi
            fi
        done

        case "$whiptail_invocation" in
            0)
                printf '%s\n' "$((whiptail_invocation + 1))" >"$whiptail_counter"
                printf '%s\n' "yes" >&2
                return 0
                ;;
            1)
                printf '%s\n' "$((whiptail_invocation + 1))" >"$whiptail_counter"
                return 1
                ;;
            2)
                printf '%s\n' "$((whiptail_invocation + 1))" >"$whiptail_counter"
                printf '%s\n' "yes" >&2
                return 0
                ;;
            3)
                printf '%s\n' "$((whiptail_invocation + 1))" >"$whiptail_counter"
                printf '%s\n' "no" >&2
                return 0
                ;;
        esac

        return 1
    }

    # shellcheck source=tui/locales/en-us/tuning.sh
    source tui/locales/en-us/tuning.sh
    # shellcheck source=tui/tuning.sh
    source tui/tuning.sh

    run awk -F '\t' -v title="$TITLE" '$1 == "2" && $2 == title { print $3 }' "$tuning_log"
    assert_success
    assert_output "ON OFF"

    rm -f "$tuning_log"
    rm -f "$whiptail_counter"
}

@test "homeassistant: esc on existing configuration goes back cleanly" {
    mkdir -p "$RUN_AS_HOME/.config/mycroft/skills/skill-homeassistant.oscillatelabsllc"
    cat <<'EOF' >"$RUN_AS_HOME/.config/mycroft/skills/skill-homeassistant.oscillatelabsllc/settings.json"
{
  "host": "http://homeassistant.local:8123",
  "api_key": "ha-existing"
}
EOF
    WHIPTAIL_FORCE_YESNO_STATUS="255"

    # shellcheck source=tui/homeassistant.sh
    source tui/homeassistant.sh

    assert_equal "$FEATURE_HOMEASSISTANT" "false"
    assert_equal "$HOMEASSISTANT_BACK" "true"
    assert_equal "$(dialog_value yesno "$TITLE_EXISTING" status)" "255"
}

@test "finish: shows user-scope service hint for non-tuned virtualenv installs" {
    METHOD="virtualenv"
    RASPBERRYPI_MODEL="N/A"
    TUNING="no"
    FEATURE_GUI="true"
    LOCALE="en-us"

    # shellcheck source=tui/finish.sh
    source tui/finish.sh

    finish_body="$(dialog_value msgbox "Open Voice OS Installation - Finish" response)"
    [[ "$finish_body" == *"OVOS services were installed in user systemd scope."* ]]
    [[ "$finish_body" == *"systemctl --user status ovos.service ovos-gui.service"* ]]
}

@test "finish: shows system-scope service hint for tuned Raspberry Pi installs" {
    METHOD="virtualenv"
    RASPBERRYPI_MODEL="Raspberry Pi 4"
    TUNING="yes"
    FEATURE_GUI="true"
    LOCALE="en-us"

    # shellcheck source=tui/finish.sh
    source tui/finish.sh

    finish_body="$(dialog_value msgbox "Open Voice OS Installation - Finish" response)"
    [[ "$finish_body" == *"OVOS services were installed in system systemd scope."* ]]
    [[ "$finish_body" == *"sudo systemctl status ovos.service ovos-gui.service"* ]]
}

@test "summary: normalizes mixed boolean-like states" {
    METHOD="virtualenv"
    CHANNEL="alpha"
    PROFILE="ovos"
    FEATURE_SKILLS="true"
    FEATURE_EXTRA_SKILLS="false"
    FEATURE_HOMEASSISTANT="true"
    HOMEASSISTANT_URL="http://homeassistant.local:8123"
    FEATURE_LLM="true"
    LLM_API_URL="https://llama.smartgic.io/v1"
    LLM_API_KEY="secret"
    LLM_MODEL="qwen3-nothink:latest"
    LLM_PERSONA="Keep replies short."
    TUNING="yes"
    LOCALE="en-us"
    WHIPTAIL_FORCE_YESNO_STATUS="0"

    # shellcheck source=tui/summary.sh
    source tui/summary.sh

    [[ "$CONTENT" == *"- Skills:   enabled"* ]]
    [[ "$CONTENT" == *"- Extra:    disabled"* ]]
    [[ "$CONTENT" == *"- HA:       enabled"* ]]
    [[ "$CONTENT" == *"- LLM:      enabled"* ]]
    [[ "$CONTENT" == *"- Tuning:   enabled"* ]]
}

function teardown() {
    rm -rf "$LOG_FILE" "$INSTALLER_STATE_FILE" "$WHIPTAIL_SPY_FILE" "$WHIPTAIL_DIALOG_FILE" "$WHIPTAIL_INPUT_QUEUE_FILE" "$RUN_AS_HOME"
}

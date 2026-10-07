#!/usr/bin/env bats
#
# Local speech is offered on a Raspberry Pi 5 with 8 GB or a machine at least as
# capable, on alpha installs only: the virtualenv, or containers with the ovos or
# listener profile. Everything else stays on the public servers, whatever was
# asked for.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/speech.sh

    LOG_FILE="$(mktemp)"

    # A 64-bit Linux host with AVX2 and 16 GB, which can run local speech.
    CPU_IS_CAPABLE="true"
    RASPBERRYPI_MODEL="N/A"
    TOTAL_MEMORY_MB=16000
    MOCK_UNAME_S="Linux"
    MOCK_UNAME_M="x86_64"
    MOCK_LONG_BIT="64"

    function uname() {
        case "$1" in
            -s) printf '%s\n' "$MOCK_UNAME_S" ;;
            -m) printf '%s\n' "$MOCK_UNAME_M" ;;
        esac
    }
    function getconf() {
        printf '%s\n' "$MOCK_LONG_BIT"
    }
}

function teardown() {
    rm -f "$LOG_FILE"
    unset -f uname getconf sysctl
}

@test "speech: a capable 64-bit Linux machine with 16 GB can run local speech" {
    run local_speech_hardware_supported
    assert_success
}

@test "speech: a Raspberry Pi 5 with 8 GB can run local speech" {
    MOCK_UNAME_M="aarch64"
    RASPBERRYPI_MODEL="Raspberry Pi 5 Model B Rev 1.0"
    # What an 8 GB board reports once firmware and kernel have taken their share.
    TOTAL_MEMORY_MB=8052

    run local_speech_hardware_supported
    assert_success
}

@test "speech: the Pi 500 and the Compute Module 5 count as a Pi 5" {
    MOCK_UNAME_M="aarch64"
    TOTAL_MEMORY_MB=8052

    RASPBERRYPI_MODEL="Raspberry Pi 500 Rev 1.0"
    run local_speech_hardware_supported
    assert_success

    RASPBERRYPI_MODEL="Raspberry Pi Compute Module 5 Rev 1.0"
    run local_speech_hardware_supported
    assert_success
}

@test "speech: a Raspberry Pi 5 with 4 GB stays public" {
    MOCK_UNAME_M="aarch64"
    RASPBERRYPI_MODEL="Raspberry Pi 5 Model B Rev 1.0"
    TOTAL_MEMORY_MB=4040

    run local_speech_hardware_supported
    assert_failure
}

@test "speech: a Raspberry Pi 4 stays public even with 8 GB" {
    MOCK_UNAME_M="aarch64"
    RASPBERRYPI_MODEL="Raspberry Pi 4 Model B Rev 1.5"
    TOTAL_MEMORY_MB=7810

    run local_speech_hardware_supported
    assert_failure
}

@test "speech: the memory floor is 7.5 GiB" {
    TOTAL_MEMORY_MB=7680
    run local_speech_hardware_supported
    assert_success

    TOTAL_MEMORY_MB=7679
    run local_speech_hardware_supported
    assert_failure
}

@test "speech: a CPU without AVX2 or NEON stays public" {
    CPU_IS_CAPABLE="false"

    run local_speech_hardware_supported
    assert_failure
}

@test "speech: a 32-bit userland stays public" {
    MOCK_UNAME_M="aarch64"
    MOCK_LONG_BIT="32"
    RASPBERRYPI_MODEL="Raspberry Pi 5 Model B Rev 1.0"
    TOTAL_MEMORY_MB=8052

    run local_speech_hardware_supported
    assert_failure
}

@test "speech: an Intel Mac stays public and an Apple silicon Mac does not" {
    MOCK_UNAME_S="Darwin"

    MOCK_UNAME_M="x86_64"
    run local_speech_hardware_supported
    assert_failure

    MOCK_UNAME_M="arm64"
    run local_speech_hardware_supported
    assert_success
}

@test "speech: memory on a Mac is read from hw.memsize" {
    MOCK_UNAME_S="Darwin"
    function sysctl() {
        printf '%s\n' "17179869184"
    }

    run total_memory_mb
    assert_success
    assert_output "16384"
}

@test "speech: detection exports whether this host is capable" {
    MOCK_UNAME_S="Darwin"
    MOCK_UNAME_M="arm64"
    function sysctl() {
        printf '%s\n' "8589934592"
    }

    detect_local_speech_support >/dev/null
    assert_equal "$TOTAL_MEMORY_MB" "8192"
    assert_equal "$LOCAL_SPEECH_CAPABLE" "true"

    function sysctl() {
        printf '%s\n' "4294967296"
    }
    detect_local_speech_support >/dev/null
    assert_equal "$LOCAL_SPEECH_CAPABLE" "false"
}

@test "speech: local is only available on alpha installs with audio" {
    LOCAL_SPEECH_CAPABLE="true"
    CHANNEL="alpha"
    METHOD="virtualenv"
    PROFILE="ovos"
    run local_speech_available
    assert_success

    PROFILE="satellite"
    run local_speech_available
    assert_success

    PROFILE="server"
    run local_speech_available
    assert_failure

    PROFILE="ovos"
    CHANNEL="testing"
    run local_speech_available
    assert_failure

    CHANNEL="alpha"
    METHOD="virtualenv"
    LOCAL_SPEECH_CAPABLE="false"
    run local_speech_available
    assert_failure
}

@test "speech: an available local choice is kept" {
    LOCAL_SPEECH_CAPABLE="true"
    CHANNEL="alpha"
    METHOD="virtualenv"
    PROFILE="ovos"
    SPEECH_ENGINE="local"

    normalize_speech_engine
    assert_equal "$SPEECH_ENGINE" "local"
}

@test "speech: local where it is not available falls back to public and says so" {
    LOCAL_SPEECH_CAPABLE="true"
    CHANNEL="testing"
    METHOD="virtualenv"
    PROFILE="ovos"
    SPEECH_ENGINE="local"

    run normalize_speech_engine
    assert_success
    assert_output --partial "Using the public servers instead"

    normalize_speech_engine >/dev/null
    assert_equal "$SPEECH_ENGINE" "public"
}

@test "speech: nothing chosen means public" {
    unset SPEECH_ENGINE
    LOCAL_SPEECH_CAPABLE="true"
    CHANNEL="alpha"
    METHOD="virtualenv"
    PROFILE="ovos"

    run normalize_speech_engine
    assert_output ""

    normalize_speech_engine
    assert_equal "$SPEECH_ENGINE" "public"
}

function run_scenario_with_speech_engine() {
    local value="$1"
    local scenario_file yq_mock
    scenario_file="$(mktemp)"
    yq_mock="$(mktemp)"

    printf 'speech_engine: %s\n' "$value" >"$scenario_file"
    {
        printf '%s\n' '#!/usr/bin/env bash'
        printf '%s\n' 'if [ "$1" = '"'"'to_entries | map([.key, .value] | join("=")) | .[]'"'"' ]; then'
        printf '%s\n' '    printf "%s\n" uninstall=false method=virtualenv channel=alpha profile=ovos features=enabled raspberry_pi_tuning=false share_telemetry=false share_usage_telemetry=false'
        printf '    printf "%%s\\n" speech_engine=%s\n' "$value"
        printf '%s\n' 'elif [ "$1" = '"'"'.features | to_entries | map([.key, .value] | join("=")) | .[]'"'"' ]; then'
        printf '%s\n' '    printf "%s\n" skills=true'
        printf '%s\n' 'fi'
    } >"$yq_mock"
    chmod +x "$yq_mock"

    run bash -c '
        cd "$1"
        source utils/constants.sh
        source utils/common.sh
        export SCENARIO_PATH="$2"
        export YQ_BINARY_PATH="$3"
        source utils/scenario.sh
        printf "%s|%s|%s\n" "${SPEECH_ENGINE:-unset}" "${SCENARIO_NOT_SUPPORTED:-false}" "${SCENARIO_ERROR:-}"
    ' bash "$BATS_TEST_DIRNAME/../.." "$scenario_file" "$yq_mock"

    rm -f "$scenario_file" "$yq_mock"
}

@test "speech: a scenario can ask for local or public speech" {
    run_scenario_with_speech_engine "local"
    assert_success
    assert_output "local|false|"

    run_scenario_with_speech_engine "public"
    assert_success
    assert_output "public|false|"
}

@test "speech: a scenario with an unknown speech engine is rejected" {
    run_scenario_with_speech_engine "offline"
    assert_success
    assert_output "unset|true|speech_engine: offline (expected: local, public)"
}

@test "speech: containers get local speech for the ovos and listener profiles only" {
    LOCAL_SPEECH_CAPABLE="true"
    CHANNEL="alpha"
    METHOD="containers"

    PROFILE="ovos"
    run local_speech_available
    assert_success

    PROFILE="listener"
    run local_speech_available
    assert_success

    # A containers satellite runs hivemind-docker, whose images carry no speech plugins.
    PROFILE="satellite"
    run local_speech_available
    assert_failure

    PROFILE="server"
    run local_speech_available
    assert_failure

    PROFILE="ovos"
    CHANNEL="testing"
    run local_speech_available
    assert_failure
}

# The tasks that write local speech into mycroft.conf, run for real against a stand-in
# for the virtualenv's python: it prints a log line, the way ovos_utils does on stdout,
# then the result speech_setup.py would have printed.
function speech_tasks_setup() {
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        skip "ansible-playbook is not available"
    fi

    SPEECH_DIR="$(mktemp -d "${BATS_TEST_TMPDIR:-/tmp}/speech.XXXXXX")"
    SPEECH_CONF="$SPEECH_DIR/mycroft.conf"
    SPEECH_RESULT="$SPEECH_DIR/result"
    SPEECH_RC="$SPEECH_DIR/rc"
    printf '0\n' >"$SPEECH_RC"

    cat >"$SPEECH_DIR/python" <<STUB
#!/bin/sh
echo "2026-10-07 12:00:00.000 - OVOS - ovos_config.config:load:1 - INFO - loading"
cat "$SPEECH_RESULT"
rc="\$(cat "$SPEECH_RC")"
[ "\$rc" = 0 ] || echo "ModuleNotFoundError: No module named 'ovos_config'" >&2
exit "\$rc"
STUB
    chmod +x "$SPEECH_DIR/python"

    cat >"$SPEECH_DIR/play.yml" <<'YAML'
- hosts: localhost
  gather_facts: false
  tasks:
    - name: Run the local speech tasks
      ansible.builtin.include_role:
        name: ovos_config
        tasks_from: speech.yml
    - name: Say what the run decided
      ansible.builtin.debug:
        msg: >-
          ENGINES={{ ovos_config_speech_stt_engine }},{{ ovos_config_speech_tts_engine }}
          CHANGED={{ ovos_config_speech_configuration.changed | default(false) }}
YAML
}

function run_speech_tasks() {
    printf '%s\n' "$1" >"$SPEECH_RESULT"
    run ansible-playbook -i localhost, -c local "$SPEECH_DIR/play.yml" -e "{
        \"ansible_become\": false,
        \"ovos_config_speech_python\": \"$SPEECH_DIR/python\",
        \"ovos_config_mycroft_conf_path\": \"$SPEECH_CONF\",
        \"ovos_config_mycroft_conf_owner\": \"$(id -un)\",
        \"ovos_config_mycroft_conf_group\": \"$(id -gn)\",
        \"ovos_config_mycroft_conf_mode\": \"0644\",
        \"ovos_installer_user\": \"$(id -un)\",
        \"ovos_installer_locale\": \"es-es\",
        \"ovos_installer_ovos_config_tts_gender\": \"--male\"
    }"
}

LOCAL_STT='{"module": "ovos-stt-plugin-onnx-asr", "fallback_module": "", "ovos-stt-plugin-onnx-asr": {"model": "parakeet-es", "quantization": "int8"}, "ovos-stt-plugin-server": {"urls": ["https://zuazo-es.tigregotico.pt/stt"]}}'
LOCAL_TTS='{"module": "ovos-tts-plugin-phoonnx", "ovos-tts-plugin-phoonnx": {"voice": "OpenVoiceOS/pipertts_es-ES_miro"}}'
PUBLIC_TTS='{"module": "ovos-tts-plugin-server", "ovos-tts-plugin-server": {"voice": "sharvard-medium#M"}}'

@test "speech: what works here is written, with the public STT server as its fallback" {
    speech_tasks_setup
    printf '{"lang": "es-es", "websocket": {"port": 8181}}\n' >"$SPEECH_CONF"

    run_speech_tasks "{\"stt\": $LOCAL_STT, \"tts\": $LOCAL_TTS, \"notes\": []}"
    assert_success
    assert_output --partial "ENGINES=local,local CHANGED=True"

    run jq -c '[.stt.module, .stt.fallback_module, .stt["ovos-stt-plugin-server"].urls[0], .tts["ovos-tts-plugin-phoonnx"].voice, .websocket.port]' "$SPEECH_CONF"
    assert_output '["ovos-stt-plugin-onnx-asr","ovos-stt-plugin-server","https://zuazo-es.tigregotico.pt/stt","OpenVoiceOS/pipertts_es-ES_miro",8181]'

    # A second run with the same result leaves the file alone, so it restarts nothing.
    run_speech_tasks "{\"stt\": $LOCAL_STT, \"tts\": $LOCAL_TTS, \"notes\": []}"
    assert_success
    assert_output --partial "ENGINES=local,local CHANGED=False"
}

@test "speech: a half that no longer works here does not keep the local section an earlier run wrote" {
    speech_tasks_setup
    # The virtualenv: the template carried both of the last run's sections through.
    printf '{"lang": "es-es", "stt": %s, "tts": %s}\n' "$LOCAL_STT" "$LOCAL_TTS" >"$SPEECH_CONF"

    run_speech_tasks "{\"stt\": $LOCAL_STT, \"tts\": null, \"notes\": [\"TTS OpenVoiceOS/pipertts_es-ES_miro does not work here\"]}"
    assert_success
    assert_output --partial "ENGINES=local,public CHANGED=True"
    assert_output --partial "No on-device TTS works for es-es"

    # No tts section: OVOS falls back to its own default, the public server.
    run jq -c '[.stt.module, has("tts")]' "$SPEECH_CONF"
    assert_output '["ovos-stt-plugin-onnx-asr",false]'
}

@test "speech: a half that does not work here keeps the public section autoconfigure wrote" {
    speech_tasks_setup
    # Containers: autoconfigure --online has just written the public voice for the locale.
    printf '{"lang": "es-es", "tts": %s}\n' "$PUBLIC_TTS" >"$SPEECH_CONF"

    run_speech_tasks "{\"stt\": $LOCAL_STT, \"tts\": null, \"notes\": []}"
    assert_success
    assert_output --partial "ENGINES=local,public CHANGED=True"

    run jq -c '[.stt.module, .tts.module, .tts["ovos-tts-plugin-server"].voice]' "$SPEECH_CONF"
    assert_output '["ovos-stt-plugin-onnx-asr","ovos-tts-plugin-server","sharvard-medium#M"]'
}

@test "speech: a setup that cannot run leaves speech public instead of ending the install" {
    speech_tasks_setup
    printf '{"lang": "es-es", "stt": %s, "tts": %s}\n' "$LOCAL_STT" "$PUBLIC_TTS" >"$SPEECH_CONF"
    printf '1\n' >"$SPEECH_RC"

    run_speech_tasks ""
    assert_success
    assert_output --partial "The local speech setup did not finish: ModuleNotFoundError"
    assert_output --partial "ENGINES=public,public CHANGED=True"

    run jq -c '[has("stt"), .tts.module]' "$SPEECH_CONF"
    assert_output '[false,"ovos-tts-plugin-server"]'
}

@test "speech: a mycroft.conf that is not plain JSON is left as it is" {
    speech_tasks_setup
    printf '// hand-edited\n{"lang": "es-es"}\n' >"$SPEECH_CONF"
    cp "$SPEECH_CONF" "$SPEECH_DIR/before"

    run_speech_tasks "{\"stt\": $LOCAL_STT, \"tts\": $LOCAL_TTS, \"notes\": []}"
    assert_success
    assert_output --partial "is not plain JSON"
    assert_output --partial "ENGINES=public,public"

    run cmp "$SPEECH_DIR/before" "$SPEECH_CONF"
    assert_success
}

@test "speech: a containers uninstall removes the model volumes, and still spares STT and TTS servers" {
    if ! command -v ansible-playbook >/dev/null 2>&1; then
        skip "ansible-playbook is not available"
    fi
    if ! ansible-doc -t module community.docker.docker_volume >/dev/null 2>&1; then
        skip "the community.docker collection is not installed"
    fi

    # The real uninstall tasks, with Docker out of reach: the sweep's selection runs
    # against what docker_host_info would have listed, and nothing is removed.
    local play
    play="$(mktemp "${BATS_TEST_TMPDIR:-/tmp}/sweep.XXXXXX.yml")"
    cat >"$play" <<'YAML'
- hosts: localhost
  gather_facts: false
  tasks:
    - name: Run the containers uninstall
      ansible.builtin.include_role:
        name: ovos_containers
        tasks_from: uninstall.yml
    - name: Say what the sweep picked
      ansible.builtin.debug:
        msg: "VOLUMES={{ ovos_containers_uninstall_target_volumes | sort | join(',') }}"
YAML

    # The model volumes start "ovos_stt" and "ovos_tts", the prefixes that protect
    # STT and TTS servers people run themselves. Removed only while the composition
    # directory still existed, they outlived any uninstall after a reboot.
    run ansible-playbook -i localhost, -c local "$play" -e '{
        "ansible_become": false,
        "ovos_containers_docker_socket_path": "/nonexistent/docker.sock",
        "ovos_containers_cmdline_path": "/nonexistent/cmdline.txt",
        "ovos_installer_docker_compose_remove_volumes": false,
        "ovos_containers_remove_directories": [],
        "ovos_containers_repo_directories": [],
        "ovos_containers_host_info": {"containers": [], "networks": [], "volumes": [
            {"Name": "ovos_stt_models", "Labels": {"com.docker.compose.project": "ovos"}},
            {"Name": "ovos_tts_models", "Labels": {"com.docker.compose.project": "ovos"}},
            {"Name": "ovos_tts_cache", "Labels": {"com.docker.compose.project": "ovos"}},
            {"Name": "ovos_models", "Labels": {"com.docker.compose.project": "ovos"}},
            {"Name": "ovos_tts_server_data", "Labels": {"com.docker.compose.project": "ovos"}},
            {"Name": "ovos_stt_whisper", "Labels": {"com.docker.compose.project": "ovos"}},
            {"Name": "somebody_else", "Labels": {"com.docker.compose.project": "other"}}
        ]}
    }'
    rm -f "$play"
    assert_success
    assert_output --partial "VOLUMES=ovos_models,ovos_stt_models,ovos_tts_cache,ovos_tts_models"
}

#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
    RASPBERRYPI_MODEL="N/A"
    DETECT_SOUND_BACKUP=""
    if [ -f "utils/detect_sound.py" ]; then
        DETECT_SOUND_BACKUP="$(mktemp)"
        cp "utils/detect_sound.py" "$DETECT_SOUND_BACKUP"
    fi
}

# Test printf migration from echo -e
@test "printf_migration_on_error" {
    # Mock the ask_optin function to avoid interactive input
    function ask_optin() {
        return 0  # Simulate user agreeing
    }
    function curl() {
        echo "https://paste.example.com/test-url"
    }
    export -f ask_optin curl

    touch "$LOG_FILE"

    run on_error
    assert_failure
    # Should contain printf-formatted output
    assert_output --partial "Unable to finalize the process"
    assert_output --partial "Please share this URL with us"

    unset -f ask_optin curl
}

@test "printf_migration_detect_user" {
    USER_ID="1000"
    run detect_user
    assert_failure
    assert_output --partial "This script must be run as root"
}

@test "printf_migration_detect_sound" {
    skip "Complex sound server detection mocking"
}

@test "detect_sound_helper_exists_and_supports_macos" {
    run test -f utils/detect_sound.py
    assert_success

    run grep -q "platform.system() == \"Darwin\"" utils/detect_sound.py
    assert_success

    run grep -q "return \"CoreAudio\"" utils/detect_sound.py
    assert_success

    run grep -q "shutil.which(\"pgrep\")" utils/detect_sound.py
    assert_success

    run grep -F -q 'command.extend(["-u", username])' utils/detect_sound.py
    assert_success
}

@test "printf_migration_required_packages" {
    DISTRO_NAME="debian"
    function apt_ensure() {
        return 0
    }
    export -f apt_ensure
    run required_packages
    assert_success
    assert_output --partial "Validating installer package requirements"
    unset apt_ensure
}

# Test quoting consistency
@test "quoting_consistency_variables" {
    USER_ID="0"
    SUDO_USER="testuser"
    SUDO_UID="1000"
    INSTALLER_VENV_NAME="ovos-installer"

    # Mock functions that detect_user calls
    function getent() {
        if [[ "$1" == "passwd" && "$2" == "testuser" ]]; then
            echo "testuser:x:1000:1000:Test User:/home/testuser:/bin/bash"
        fi
    }
    function id() {
        if [[ "$1" == "-ng" ]]; then
            echo "testuser"
        else
            echo "uid=1000(testuser) gid=1000(testuser) groups=1000(testuser)"
        fi
    }
    export -f getent id

    detect_user
    # Variables should be properly quoted in function calls
    assert_equal "${RUN_AS}" "testuser"
    assert_equal "${RUN_AS_UID}" "1000"

    unset -f getent id
}

@test "quoting_consistency_array_access" {
    local test_array=("value1" "value2")
    run in_array test_array "value1"
    assert_success
}

# Test local variable usage
@test "local_variables_detect_sound" {
    # Set required environment variables
    RUN_AS_UID="1000"
    RUN_AS_HOME="/home/testuser"

    function python3() {
        if [[ "$1" == *"detect_sound.py"* ]]; then
            echo "PulseAudio"
        fi
    }
    export -f python3

    touch "utils/detect_sound.py"

    # Call detect_sound directly (not with run) to test variable setting
    detect_sound
    assert_equal "${SOUND_SERVER}" "PulseAudio"

    rm -f "utils/detect_sound.py"
    unset python3
}

@test "local_variables_required_packages" {
    DISTRO_NAME="debian"
    function apt_ensure() {
        return 0
    }
    export -f apt_ensure
    run required_packages
    assert_success
    unset apt_ensure
}



# Test constants alphabetical ordering
@test "constants_alphabetical_order" {
    # Test that constants are properly ordered
    # This ensures maintainability
    assert_equal "${ANSIBLE_LOG_FILE}" "/var/log/ovos-ansible.log"
    assert_equal "${ATMEGA328P_SIGNATURE}" ":030000001E950F3B"
    assert_equal "${AVRDUDE_ARTIFACT_ARCH}" "aarch64"
    assert_equal "${AVRDUDE_ARTIFACT_BASE_URL}" "https://artifacts.smartgic.io/avrdude"
    assert_equal "${AVRDUDE_ARTIFACT_VERSION}" "v8.1"
    assert_equal "${AVRDUDE_BINARY_PATH}" "/usr/local/bin/avrdude"
    assert_equal "${AVRDUDE_CONFIG_PATH}" "/usr/local/etc/avrdude.conf"
}

# Test modularity improvements
@test "function_modularity_decomposition" {
    # Test that required_packages calls distro-specific functions
    DISTRO_NAME="debian"
    function apt_ensure() {
        return 0
    }
    export -f apt_ensure
    run required_packages
    assert_success
    unset apt_ensure
}

@test "virtualenv_pins_setuptools_for_pkg_resources" {
    # setuptools>=82 dropped pkg_resources, which breaks ovos_plugin_manager imports.
    run grep -q "ovos_installer_setuptools_package" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_setuptools_package" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    # Guard against regression to an unpinned setuptools upgrade.
    run grep -q "pip install -U pip setuptools wheel" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_failure

    run grep -q "ovos_virtualenv_setuptools_package" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success
}

@test "virtualenv_numpy_default_tracks_python_abi" {
    local file="ansible/roles/ovos_virtualenv/defaults/main.yml"

    run grep -F -q "(ovos_virtualenv_venv_python_minor | int) >= 13" "$file"
    assert_success

    run grep -F -q "'numpy>=2.1,<3'" "$file"
    assert_success

    run grep -F -q "'numpy==1.26.4'" "$file"
    assert_success
}

@test "virtualenv_runtime_bootstrap_numpy_uses_venv_python_version" {
    local file="ansible/roles/ovos_virtualenv/tasks/venv.yml"

    run grep -q "Detect OVOS venv runtime Python version" "$file"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Detect OVOS venv runtime Python version\" \"$file\" | grep -q -- '{{ ovos_virtualenv_path }}/bin/python'"
    assert_success

    run grep -q "Resolve runtime bootstrap numpy package from OVOS venv Python" "$file"
    assert_success

    run grep -q "ovos_virtualenv_runtime_numpy_package" "$file"
    assert_success

    run grep -q "'numpy>=2.1,<3'" "$file"
    assert_success
}

@test "macos_includes_precise_onnx_in_virtualenv_requirements" {
    run grep -q "ovos-ww-plugin-precise-onnx" ansible/roles/ovos_virtualenv/templates/virtualenv/core-requirements.txt.j2
    assert_success

    run grep -q "ovos-ww-plugin-precise-onnx" ansible/roles/ovos_virtualenv/templates/virtualenv/satellite-requirements.txt.j2
    assert_success
}

@test "mycroft_conf_uses_precise_onnx_for_macos_listener" {
    run grep -q "_ovos_listener_has_wake_word" ansible/roles/ovos_config/templates/mycroft.conf.j2
    assert_success

    run grep -q "\"fake_barge_in\": false" ansible/roles/ovos_config/templates/mycroft.conf.j2
    assert_success

    run grep -q "\"module\": \"ovos-microphone-plugin-sounddevice\"" ansible/roles/ovos_config/templates/mycroft.conf.j2
    assert_success

    run grep -q "\"module\": \"ovos-ww-plugin-precise-onnx\"" ansible/roles/ovos_config/templates/mycroft.conf.j2
    assert_success
}

@test "mycroft_conf_uses_top_level_hotwords_configuration" {
    local conf_file="ansible/roles/ovos_config/templates/mycroft.conf.j2"
    local listener_scope_file
    listener_scope_file="$(mktemp)"

    run awk '/"listener": \{/{in_listener=1} in_listener {print} in_listener && /^  },$/{in_listener=0; exit}' "$conf_file"
    assert_success

    printf "%s\n" "$output" > "$listener_scope_file"

    run grep -F -q "\"hotwords\": {" "$listener_scope_file"
    assert_failure

    run grep -F -q "\"hotwords\": {" "$conf_file"
    assert_success

    run grep -F -q "\"listen\": true" "$conf_file"
    assert_success

    run grep -F -q "\"active\": true" "$conf_file"
    assert_success

    rm -f "$listener_scope_file"
}

@test "mycroft_conf_hardens_mark2_wakeword_defaults" {
    local conf_file="ansible/roles/ovos_config/templates/mycroft.conf.j2"

    run grep -q "ovos_installer_mark2_hotword_sensitivity: 0.55" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_mark2_hotword_trigger_level: 3" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_mark2_vad_pre_wake_enabled: false" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -F -q "{% set _ovos_hotword_sensitivity = ovos_config_mark2_hotword_sensitivity if _ovos_is_mark2 else ovos_config_hotword_sensitivity %}" "$conf_file"
    assert_success

    run grep -F -q "{% set _ovos_hotword_trigger_level = ovos_config_mark2_hotword_trigger_level if _ovos_is_mark2 else ovos_config_hotword_trigger_level %}" "$conf_file"
    assert_success

    run grep -F -q "\"vad_pre_wake_enabled\": {{ ovos_config_mark2_vad_pre_wake_enabled | bool | lower }}" "$conf_file"
    assert_success
}

@test "sounddevice_microphone_defaults_include_mark2_and_devkit" {
    local core_file="ansible/roles/ovos_virtualenv/templates/virtualenv/core-requirements.txt.j2"
    local sat_file="ansible/roles/ovos_virtualenv/templates/virtualenv/satellite-requirements.txt.j2"
    local conf_file="ansible/roles/ovos_config/templates/mycroft.conf.j2"

    run grep -F -q "{% if ansible_facts.system == 'Darwin' or 'tas5806' in (ovos_installer_i2c_devices | default([])) %}" "$core_file"
    assert_success

    run grep -F -q "{% if ansible_facts.system == 'Darwin' or 'tas5806' in (ovos_installer_i2c_devices | default([])) %}" "$sat_file"
    assert_success

    run grep -q "_ovos_use_sounddevice_mic" "$conf_file"
    assert_success

    run grep -F -q "{% if _ovos_use_sounddevice_mic %}" "$conf_file"
    assert_success
}

@test "mycroft_conf_applies_sounddevice_tuning_for_mark2_only" {
    local conf_file="ansible/roles/ovos_config/templates/mycroft.conf.j2"

    run grep -F -q "{% set _ovos_is_mark2 = ('tas5806' in (ovos_installer_i2c_devices | default([]))) and ('attiny1614' not in (ovos_installer_i2c_devices | default([]))) %}" "$conf_file"
    assert_success

    run grep -F -q "\"module\": \"ovos-microphone-plugin-sounddevice\"{% if _ovos_is_mark2 %}" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-microphone-plugin-sounddevice\": {" "$conf_file"
    assert_success

    run grep -F -q "\"queue_maxsize\": 32" "$conf_file"
    assert_success
}

@test "mycroft_conf_sets_mark2_compatible_intent_pipeline" {
    local conf_file="ansible/roles/ovos_config/templates/mycroft.conf.j2"

    run grep -Eq "^\\{% if _ovos_mark2_ocp_legacy or _ovos_persona_llm_enabled %\\}$" "$conf_file"
    assert_failure

    run grep -F -q "\"pipeline\": [" "$conf_file"
    assert_success

    run bash -c "grep -B1 -F -- '\"pipeline\": [' \"$conf_file\" | grep -F -q '{% if _ovos_mark2_ocp_legacy %}'"
    assert_failure

    run grep -F -q "{% if _ovos_mark2_ocp_legacy %}" "$conf_file"
    assert_success

    run grep -F -q "\"legacy\": true" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-stop-pipeline-plugin-high\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-converse-pipeline-plugin\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-ocp-pipeline-plugin-high\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-persona-pipeline-plugin-high\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-padatious-pipeline-plugin-high\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-m2v-pipeline-high\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-fallback-pipeline-plugin-high\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-adapt-pipeline-plugin-high\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-stop-pipeline-plugin-medium\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-adapt-pipeline-plugin-medium\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-common-query-pipeline-plugin\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-fallback-pipeline-plugin-medium\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-persona-pipeline-plugin-low\"" "$conf_file"
    assert_success

    run grep -F -q "\"ovos-fallback-pipeline-plugin-low\"" "$conf_file"
    assert_success

    run bash -c 'prev=0; for entry in "ovos-stop-pipeline-plugin-high" "ovos-converse-pipeline-plugin" "ovos-ocp-pipeline-plugin-high" "ovos-persona-pipeline-plugin-high" "ovos-padatious-pipeline-plugin-high" "ovos-m2v-pipeline-high" "ovos-fallback-pipeline-plugin-high" "ovos-adapt-pipeline-plugin-high" "ovos-stop-pipeline-plugin-medium" "ovos-adapt-pipeline-plugin-medium" "ovos-common-query-pipeline-plugin" "ovos-fallback-pipeline-plugin-medium" "ovos-persona-pipeline-plugin-low" "ovos-fallback-pipeline-plugin-low"; do line=$(grep -n -F -- "\"$entry\"" "$1" | head -n1 | cut -d: -f1); [ -n "$line" ] || exit 1; [ "$line" -gt "$prev" ] || exit 1; prev=$line; done' _ "$conf_file"
    assert_success
}

@test "mycroft_conf_sets_gui_idle_display_skill_to_current_homescreen_id" {
    local file="ansible/roles/ovos_config/templates/mycroft.conf.j2"

    run grep -q "{% if ovos_installer_feature_gui | bool %}" "$file"
    assert_success

    run bash -c "grep -A4 -F -- \"{% if ovos_installer_feature_gui | bool %}\" \"$file\" | grep -q -- \"\\\"idle_display_skill\\\": \\\"skill-ovos-homescreen.openvoiceos\\\"\""
    assert_success

    run grep -q "\"idle_display_skill\": \"ovos-skill-homescreen.openvoiceos\"" "$file"
    assert_failure
}

@test "mycroft_conf_enables_ipgeo_phal_plugin_and_sets_mark2_ip_lookup_url" {
    local conf_file="ansible/roles/ovos_config/templates/mycroft.conf.j2"
    local mark2_scoped_file
    mark2_scoped_file="$(mktemp)"

    run awk "/{% if 'tas5806' in ovos_installer_i2c_devices %}/ { in_mark2=1 } in_mark2 { print } in_mark2 && /{% endif %}/ { in_mark2=0 }" "$conf_file"
    assert_success

    printf "%s\n" "$output" > "$mark2_scoped_file"

    run test -s "$mark2_scoped_file"
    assert_success

    run grep -F -q "\"network_tests\": {" "$mark2_scoped_file"
    assert_success

    run grep -F -q "\"ip_url\": \"{{ ovos_config_mark2_network_tests_ip_url }}\"" "$mark2_scoped_file"
    assert_success

    run grep -F -q "\"ovos-phal-plugin-ipgeo\": {" "$mark2_scoped_file"
    assert_success

    run bash -c "grep -A4 -F -- \"\\\"ovos-phal-plugin-ipgeo\\\": {\" \"$mark2_scoped_file\" | grep -q -- \"\\\"enabled\\\": true\""
    assert_success

    run grep -F -q "\"ovos-PHAL-plugin-alsa\": {" "$mark2_scoped_file"
    assert_failure

    rm -f "$mark2_scoped_file"
}

@test "macos_never_requests_precise_lite_plugin" {
    run grep -R -n "ovos-ww-plugin-precise-lite" ansible/roles/ovos_virtualenv/templates/virtualenv
    assert_failure

    run grep -q "ovos-dinkum-listener\\[{{ 'extras' if ansible_facts.system == 'Darwin' else 'extras,linux' }}\\]" ansible/roles/ovos_virtualenv/templates/virtualenv/core-requirements.txt.j2
    assert_success

    run grep -q "ovos-dinkum-listener\\[{{ 'extras' if ansible_facts.system == 'Darwin' else 'extras,linux' }}\\]" ansible/roles/ovos_virtualenv/templates/virtualenv/satellite-requirements.txt.j2
    assert_success
}

@test "rust_messagebus_download_uses_checksum_verification" {
    run grep -q "ovos_virtualenv_rust_messagebus_archive_checksum" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_rust_messagebus_archive_checksums" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_messagebus-aarch64-apple-darwin.tar.gz" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_messagebus-x86_64-apple-darwin.tar.gz" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "armv7l" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "unknown-linux-gnueabihf" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ansible.builtin.get_url" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success

    run grep -q "checksum: \"{{ ovos_virtualenv_rust_messagebus_archive_checksum }}\"" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success

    run grep -q "Assert Rust messagebus checksum is available for selected target/version" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success

    run grep -q "Check Rust messagebus binary presence" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success

    run grep -q "ovos_virtualenv_rust_messagebus_download is changed" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success

    run grep -q "ovos_virtualenv_rust_messagebus_binary_stat.stat.exists" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success

    run grep -q "Extract Rust messagebus archive with tar" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success

    run grep -q -- "- -xzf" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success

    run bash -c "grep -A6 -F -- \"- name: Ensure custom Rust messagebus archive directory exists\" ansible/roles/ovos_virtualenv/tasks/bus.yml | grep -q -- \"mode: \\\"0755\\\"\""
    assert_success

    run grep -F -q "(ovos_virtualenv_rust_messagebus_archive_path | dirname) != '/tmp'" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_success

    run grep -q "Remove Rust messagebus archive after extraction" ansible/roles/ovos_virtualenv/tasks/bus.yml
    assert_failure
}

@test "macos_homebrew_uses_espeak_ng_formula" {
    run grep -q -- "- espeak-ng" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q -- "- espeak$" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_failure
}

@test "macos_fann_build_env_is_exported_for_uv_install" {
    run grep -q "ovos_virtualenv_macos_fann_linker_flags" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_macos_fann_library_path" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_macos_fann_pkg_config_path" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "'LDFLAGS': ovos_virtualenv_macos_fann_linker_flags" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "'LIBRARY_PATH': ovos_virtualenv_macos_fann_library_path" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "'PKG_CONFIG_PATH': ovos_virtualenv_macos_fann_pkg_config_path" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success
}

@test "virtualenv_uv_uses_dedicated_cache_directory" {
    run grep -q "ovos_virtualenv_uv_cache_dir" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_uv_environment" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "'UV_CACHE_DIR': ovos_virtualenv_uv_cache_dir" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "Ensure dedicated uv cache directory exists" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "environment: \"{{ ovos_virtualenv_uv_environment }}\"" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success
}

@test "virtualenv_caches_constraints_file_and_uses_local_constraints_for_uv" {
    local defaults_file="ansible/roles/ovos_virtualenv/defaults/main.yml"
    local tasks_file="ansible/roles/ovos_virtualenv/tasks/venv.yml"

    run grep -q "ovos_virtualenv_constraints_url" "$defaults_file"
    assert_success

    run grep -q "ovos_virtualenv_constraints_path" "$defaults_file"
    assert_success

    run grep -q "ovos_virtualenv_constraints_refresh_interval" "$defaults_file"
    assert_success

    run grep -q "ovos_virtualenv_constraints_force_sync" "$defaults_file"
    assert_success

    run grep -q "ovos_virtualenv_uv_install_retries" "$defaults_file"
    assert_success

    run grep -q "ovos_virtualenv_uv_install_delay" "$defaults_file"
    assert_success

    run grep -q "Check cached OVOS constraints file" "$tasks_file"
    assert_success

    run grep -q "Cache OVOS constraints file" "$tasks_file"
    assert_success

    run bash -c "grep -A6 -F -- \"- name: Install Open Voice OS in Python venv\" \"$tasks_file\" | grep -F -q -- \"--constraint {{ ovos_virtualenv_constraints_path }}\""
    assert_success

    run grep -q "retries: \"{{ ovos_virtualenv_uv_install_retries | int }}\"" "$tasks_file"
    assert_success

    run grep -q "delay: \"{{ ovos_virtualenv_uv_install_delay | int }}\"" "$tasks_file"
    assert_success
}

@test "virtualenv_uv_uses_consistent_exec_path_with_homebrew_prefixes" {
    run grep -q "ovos_virtualenv_installer_venv_path" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_uv_exec_path" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "/opt/homebrew/bin:/usr/local/bin" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "'PATH': ovos_virtualenv_uv_exec_path" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success
}

@test "virtualenv_uv_prerelease_gating_uses_target_venv_python" {
    run grep -q "ovos_installer_venv_python_parts" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_venv_python_major" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_venv_python_minor" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_venv_python_parts\\[1:\\] | first | default('0')" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_uv_allow_prerelease: \"{{ (ovos_installer_venv_python_major | int) == 3 and (ovos_installer_venv_python_minor | int) >= 13 }}\"" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ansible_facts.python.version" ansible/roles/ovos_installer/defaults/main.yml
    assert_failure

    run grep -q "ovos_virtualenv_venv_python_parts" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_venv_python_major" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_venv_python_minor" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_venv_python_parts\\[1:\\] | first | default('0')" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "((ovos_virtualenv_venv_python_major | int) == 3)" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "((ovos_virtualenv_venv_python_minor | int) >= 13)" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run bash -c "grep -A8 -F -- \"ovos_virtualenv_uv_allow_prerelease\" ansible/roles/ovos_virtualenv/defaults/main.yml | grep -q -- \"ansible_facts.python\""
    assert_failure
}

@test "virtualenv_ensures_python_command_shim_exists" {
    run grep -q "Resolve OVOS venv base interpreter with uv" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "uv python find {{ ovos_virtualenv_venv_python }}" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "Check OVOS venv base interpreter target" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "executable | default(false)" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "Assert OVOS venv base interpreter is available" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "regex_escape" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "Ensure OVOS venv versioned python points to base interpreter" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "Ensure OVOS venv python3 symlink points to versioned executable" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "Ensure OVOS venv python command points to versioned executable" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "dest: \"{{ ovos_virtualenv_path }}/bin/python\"" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "src: \"{{ ovos_virtualenv_path }}/bin/python{{ ovos_virtualenv_venv_python }}\"" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "follow: false" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "force: true" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "src: \"{{ ovos_virtualenv_base_python_executable.stdout | trim }}\"" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "ovos_virtualenv_path ~ '/bin/python'" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_failure

    run grep -q "Read OVOS venv pyvenv.cfg" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_failure
}

@test "virtualenv_uv_pip_tasks_run_as_installer_user" {
    local file="ansible/roles/ovos_virtualenv/tasks/venv.yml"

    run bash -c "grep -A4 -F -- \"- name: Install wheel bootstrap package (macOS or non-AVX/SIMD hosts)\" \"$file\" | grep -q -- 'become_user: \"{{ ovos_installer_user }}\"'"
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Install ggwave Python library\" \"$file\" | grep -q -- 'become_user: \"{{ ovos_installer_user }}\"'"
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Install Open Voice OS in Python venv\" \"$file\" | grep -q -- 'become_user: \"{{ ovos_installer_user }}\"'"
    assert_success

    run bash -c "grep -A6 -F -- \"- name: Ensure runtime bootstrap Python libraries are installed\" \"$file\" | grep -q -- 'become_user: \"{{ ovos_installer_user }}\"'"
    assert_success
}

@test "virtualenv_uv_bootstrap_and_runtime_installs_skip_cleaning" {
    local file="ansible/roles/ovos_virtualenv/tasks/venv.yml"

    run bash -c "grep -A12 -F -- \"- name: Install wheel bootstrap package (macOS or non-AVX/SIMD hosts)\" \"$file\" | grep -F -q -- 'not (ovos_virtualenv_is_cleaning | bool)'"
    assert_success

    run bash -c "grep -A12 -F -- \"- name: Install ggwave Python library\" \"$file\" | grep -F -q -- 'not (ovos_virtualenv_is_cleaning | bool)'"
    assert_success

    run bash -c "grep -A12 -F -- \"- name: Ensure runtime bootstrap Python libraries are installed\" \"$file\" | grep -F -q -- 'not (ovos_virtualenv_is_cleaning | bool)'"
    assert_success
}

@test "virtualenv_repairs_ownership_before_python_package_installs" {
    local defaults_file="ansible/roles/ovos_virtualenv/defaults/main.yml"
    local file="ansible/roles/ovos_virtualenv/tasks/venv.yml"

    run grep -q "ovos_virtualenv_repair_ownership" "$defaults_file"
    assert_success

    run grep -q "Ensure OVOS virtualenv ownership is aligned before package installs" "$file"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Ensure OVOS virtualenv ownership is aligned before package installs\" \"$file\" | grep -q -- 'recurse: true'"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Ensure OVOS virtualenv ownership is aligned before package installs\" \"$file\" | grep -q -- 'owner: \"{{ ovos_installer_user }}\"'"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Ensure OVOS virtualenv ownership is aligned before package installs\" \"$file\" | grep -q -- 'group: \"{{ ovos_installer_group }}\"'"
    assert_success

    run bash -c "grep -A12 -F -- \"- name: Ensure OVOS virtualenv ownership is aligned before package installs\" \"$file\" | grep -F -q -- 'ovos_virtualenv_repair_ownership | bool or (ovos_virtualenv_venv_create is changed)'"
    assert_success

    run bash -c "awk '/Ensure OVOS virtualenv ownership is aligned before package installs/{owner_line=NR} /Ensure runtime bootstrap Python libraries are installed/{runtime_bootstrap_line=NR} END{exit !(owner_line>0 && runtime_bootstrap_line>0 && owner_line<runtime_bootstrap_line)}' \"$file\""
    assert_success
}

@test "ovos_config_defaults_guard_ansible_facts_system_references" {
    local file="ansible/roles/ovos_config/defaults/main.yml"

    run grep -F -q "(ansible_facts.system | default('')) == 'Linux'" "$file"
    assert_success
}

@test "macos_fann2_build_has_swig2_compatibility_shim" {
    run grep -q "Resolve swig binary path for fann2 builds (macOS)" ansible/roles/ovos_virtualenv/tasks/packages.yml
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Resolve swig binary path for fann2 builds (macOS)\" ansible/roles/ovos_virtualenv/tasks/packages.yml | grep -q -- \"failed_when: false\""
    assert_success

    run grep -q "Ensure swig2.0 compatibility shim exists (macOS)" ansible/roles/ovos_virtualenv/tasks/packages.yml
    assert_success

    run grep -q "dest: \"{{ ovos_installer_user_home }}/.local/bin/swig2.0\"" ansible/roles/ovos_virtualenv/tasks/packages.yml
    assert_success
}

@test "virtualenv_uses_platform_shell_init_file" {
    run grep -q "ovos_virtualenv_shell_init_file" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "'.zshrc' if (ansible_facts.system | default('')) == 'Darwin' else '.bashrc'" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "path: \"{{ ovos_virtualenv_shell_init_file }}\"" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "create: true" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "path: \"{{ ovos_virtualenv_shell_init_file }}\"" ansible/roles/ovos_virtualenv/tasks/uninstall.yml
    assert_success
}

@test "virtualenv_gui_uninstall_removes_debian_mark2_packages" {
    local file="ansible/roles/ovos_virtualenv/tasks/uninstall.yml"

    run grep -q "Remove ovos-gui package requirements (Debian Trixie Mark II/DevKit)" "$file"
    assert_success

    run bash -c "grep -A40 -F -- \"- name: Remove ovos-gui package requirements (Debian Trixie Mark II/DevKit)\" \"$file\" | grep -q -- \"state: absent\""
    assert_success

    run bash -c "grep -A40 -F -- \"- name: Remove ovos-gui package requirements (Debian Trixie Mark II/DevKit)\" \"$file\" | grep -q -- \"purge: true\""
    assert_success

    run bash -c "grep -A40 -F -- \"- name: Remove ovos-gui package requirements (Debian Trixie Mark II/DevKit)\" \"$file\" | grep -q -- \"autoremove: true\""
    assert_success

    run bash -c "grep -A50 -F -- \"- name: Remove ovos-gui package requirements (Debian Trixie Mark II/DevKit)\" \"$file\" | grep -F -q -- \"'tas5806' in (ovos_installer_i2c_devices | default([]))\""
    assert_success
}

@test "installer_assert_enforces_virtualenv_for_mark2_and_devkit" {
    local file="ansible/roles/ovos_installer/tasks/assert.yml"

    run grep -q "Assert Mark 2/DevKit-supported installer modes" "$file"
    assert_success

    run grep -F -q -- "'tas5806' in (ovos_installer_i2c_devices | default([]))" "$file"
    assert_success

    run grep -F -q -- "'attiny1614' not in (ovos_installer_i2c_devices | default([]))" "$file"
    assert_failure
}

@test "site_includes_shared_input_contract_role" {
    run grep -q "role: ovos_contract" ansible/site.yml
    assert_success

    run grep -q "Assert shared installer input contract" ansible/roles/ovos_contract/tasks/main.yml
    assert_success
}

@test "installer_includes_containers_role_only_for_containers_method" {
    local file="ansible/roles/ovos_installer/tasks/main.yml"

    run bash -c "grep -A6 -F -- \"- name: Include ovos_containers role\" \"$file\" | grep -F -q -- \"ovos_installer_method == \\\"containers\\\"\""
    assert_success

    run bash -c "grep -A6 -F -- \"- name: Include ovos_containers role\" \"$file\" | grep -F -q -- \"ovos_installer_is_cleaning\""
    assert_failure
}

@test "installer_stops_services_early_on_uninstall" {
    local file="ansible/roles/ovos_installer/tasks/main.yml"

    run bash -c "grep -A10 -F -- \"- name: Include ovos_services role for uninstall pre-stop\" \"$file\" | grep -F -q -- \"ovos_installer_is_cleaning\""
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Include ovos_services role for uninstall pre-stop\" \"$file\" | grep -F -q -- \"ansible.builtin.include_role:\""
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Include ovos_services role for uninstall pre-stop\" \"$file\" | grep -F -q -- \"ansible.builtin.import_role:\""
    assert_failure

    run bash -c "grep -A4 -F -- \"- name: Include ovos_services role for uninstall pre-stop\" \"$file\" | grep -F -q -- \"handlers_from: noop\""
    assert_success

    run test -f ansible/roles/ovos_services/handlers/noop.yml
    assert_success

    run bash -c "grep -A6 -F -- \"- name: Include ovos_services role\" \"$file\" | grep -F -q -- \"not (ovos_installer_is_cleaning | bool)\""
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Include uninstall tasks\" \"$file\" | grep -F -q -- \"ansible.builtin.include_tasks: uninstall.yml\""
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Include uninstall tasks\" \"$file\" | grep -F -q -- \"ansible.builtin.import_tasks: uninstall.yml\""
    assert_failure
}

@test "installer_removes_service_directories_after_tuning_cleanup" {
    local uninstall_file="ansible/roles/ovos_installer/tasks/uninstall.yml"
    local services_uninstall_file="ansible/roles/ovos_services/tasks/uninstall.yml"

    run bash -c "grep -A5 -F -- \"- name: Remove OVOS service directories after tuning cleanup\" \"$uninstall_file\" | grep -F -q -- \"ansible.builtin.include_role:\""
    assert_success

    run bash -c "grep -A5 -F -- \"- name: Remove OVOS service directories after tuning cleanup\" \"$uninstall_file\" | grep -F -q -- \"tasks_from: remove-directories.yml\""
    assert_success

    run bash -c "grep -A5 -F -- \"- name: Remove OVOS service directories after tuning cleanup\" \"$uninstall_file\" | grep -F -q -- \"handlers_from: noop\""
    assert_success

    run bash -c "grep -A5 -F -- \"- name: Remove OVOS service directories after tuning cleanup\" \"$uninstall_file\" | grep -F -q -- \"ansible.builtin.import_role:\""
    assert_failure

    run bash -c 'remove_line=$(grep -n -F -- "- name: Remove OVOS service directories after tuning cleanup" "$1" | head -n1 | cut -d: -f1); autoremove_line=$(grep -n -F -- "- name: Autoremove orphaned packages (Debian/Zorin)" "$1" | head -n1 | cut -d: -f1); [ -n "$remove_line" ] && [ -n "$autoremove_line" ] && [ "$remove_line" -lt "$autoremove_line" ]' _ "$uninstall_file"
    assert_success

    run grep -F -q 'loop: "{{ ovos_services_remove_directories }}"' "$services_uninstall_file"
    assert_failure
}

@test "virtualenv_gui_core_requirements_use_installable_package_name" {
    local file="ansible/roles/ovos_virtualenv/templates/virtualenv/core-requirements.txt.j2"

    run grep -q "ovos-gui\\[extras\\]" "$file"
    assert_success

    run grep -q "ovos-gui-service" "$file"
    assert_failure
}

@test "virtualenv_gui_core_requirements_include_homescreen_skill" {
    local file="ansible/roles/ovos_virtualenv/templates/virtualenv/core-requirements.txt.j2"

    run bash -c "grep -A3 -F -- \"{% if ovos_installer_feature_gui | bool %}\" \"$file\" | grep -q -- \"ovos-gui\\[extras\\]\""
    assert_success

    run bash -c "grep -A3 -F -- \"{% if ovos_installer_feature_gui | bool %}\" \"$file\" | grep -q -- \"ovos-skill-homescreen\""
    assert_success

    run bash -c "sed -n '1,20p' \"$file\" | grep -q -- \"{% if 'tas5806' in ovos_installer_i2c_devices %}\""
    assert_failure
}

@test "virtualenv_core_requirements_do_not_pin_noninstallable_pipeline_plugins" {
    local file="ansible/roles/ovos_virtualenv/templates/virtualenv/core-requirements.txt.j2"

    run grep -q "ovos-adapt-pipeline-plugin" "$file"
    assert_failure

    run grep -q "ovos-padatious-pipeline-plugin" "$file"
    assert_failure

    run grep -q "ovos-fallback-pipeline-plugin" "$file"
    assert_failure
}

@test "virtualenv_mark2_uses_phal_mk2_without_pyee_pin" {
    local file="ansible/roles/ovos_virtualenv/templates/virtualenv/core-requirements.txt.j2"

    run grep -F -q "{% if 'tas5806' in ovos_installer_i2c_devices %}" "$file"
    assert_success

    run grep -F -q "pyee==8.1.0" "$file"
    assert_failure

    run grep -F -q "ovos-PHAL-plugin-hotkeys" "$file"
    assert_failure

    run grep -F -q "ovos-PHAL[mk2]" "$file"
    assert_success
}

@test "virtualenv_mark2_does_not_pin_datetime_or_weather_skills" {
    local defaults_file="ansible/roles/ovos_virtualenv/defaults/main.yml"
    local tasks_file="ansible/roles/ovos_virtualenv/tasks/venv.yml"

    run grep -F -q "ovos_virtualenv_mark2_skill_pins:" "$defaults_file"
    assert_failure

    run grep -F -q "ovos-skill-date-time==1.1.5" "$defaults_file"
    assert_failure

    run grep -F -q "ovos-skill-weather==1.0.6" "$defaults_file"
    assert_failure

    run grep -F -q "Install known-good skill pins for Mark II" "$tasks_file"
    assert_failure

    run grep -F -q "Install known-good date-time skill for Mark II" "$tasks_file"
    assert_failure

    run grep -F -q "Install known-good weather skill for Mark II" "$tasks_file"
    assert_failure

    run grep -F -q "ovos_virtualenv_mark2_datetime_package:" "$defaults_file"
    assert_failure

    run grep -F -q "ovos_virtualenv_mark2_weather_package:" "$defaults_file"
    assert_failure
}

@test "virtualenv_mark2_does_not_pin_padatious_parser" {
    local defaults_file="ansible/roles/ovos_virtualenv/defaults/main.yml"
    local tasks_file="ansible/roles/ovos_virtualenv/tasks/venv.yml"

    run grep -F -q "ovos_virtualenv_mark2_padatious_package:" "$defaults_file"
    assert_failure

    run grep -F -q "ovos-padatious==1.4.3" "$defaults_file"
    assert_failure

    run grep -F -q "Install known-good padatious parser for Mark II" "$tasks_file"
    assert_failure
}

@test "virtualenv_installs_padatious_cache_for_all_virtualenv_installs" {
    local defaults_file="ansible/roles/ovos_virtualenv/defaults/main.yml"
    local venv_tasks_file="ansible/roles/ovos_virtualenv/tasks/venv.yml"
    local cache_tasks_file="ansible/roles/ovos_virtualenv/tasks/intent_cache.yml"

    run grep -F -q "ovos_virtualenv_padatious_cache_repo_url: https://github.com/OpenVoiceOS/padatious_cache" "$defaults_file"
    assert_success

    run grep -F -q "ovos_virtualenv_padatious_cache_repo_version: dev" "$defaults_file"
    assert_success

    run grep -F -q "ovos_virtualenv_padatious_cache_dir:" "$defaults_file"
    assert_success

    run grep -F -q "ovos_virtualenv_padatious_cache_staging_dir:" "$defaults_file"
    assert_success

    run grep -F -q "ovos_virtualenv_padatious_cache_backup_dir:" "$defaults_file"
    assert_success

    run grep -F -q "ovos_virtualenv_padatious_cache_force_sync" "$defaults_file"
    assert_success

    run grep -F -q "Include intent cache sync tasks" "$venv_tasks_file"
    assert_success

    run grep -F -q "Checkout padatious cache repository" "$cache_tasks_file"
    assert_success

    run bash -c "grep -A10 -F -- \"- name: Checkout padatious cache repository\" \"$cache_tasks_file\" | grep -F -q -- \"repo: \\\"{{ ovos_virtualenv_padatious_cache_repo_url }}\\\"\""
    assert_success

    run bash -c "grep -A10 -F -- \"- name: Checkout padatious cache repository\" \"$cache_tasks_file\" | grep -F -q -- \"version: \\\"{{ ovos_virtualenv_padatious_cache_repo_version }}\\\"\""
    assert_success

    run grep -F -q "Check staged OVOS intent cache payload exists" "$cache_tasks_file"
    assert_success

    run grep -F -q "Assert staged OVOS intent cache payload is valid" "$cache_tasks_file"
    assert_success

    run grep -F -q "Decide whether OVOS intent cache sync is required" "$cache_tasks_file"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Decide whether OVOS intent cache sync is required\" \"$cache_tasks_file\" | grep -F -q -- \"ovos_virtualenv_padatious_cache_checkout.changed\""
    assert_success

    run grep -F -q "Stage OVOS intent cache payload from padatious_cache" "$cache_tasks_file"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Stage OVOS intent cache payload from padatious_cache\" \"$cache_tasks_file\" | grep -F -q -- \"{{ ovos_virtualenv_padatious_cache_repo_path }}/intent_cache\""
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Stage OVOS intent cache payload from padatious_cache\" \"$cache_tasks_file\" | grep -F -q -- \"{{ ovos_virtualenv_padatious_cache_staging_dir }}\""
    assert_success

    run grep -F -q "Backup existing OVOS intent cache directory" "$cache_tasks_file"
    assert_success

    run grep -F -q "Activate staged OVOS intent cache directory" "$cache_tasks_file"
    assert_success

    run grep -F -q "Remove existing OVOS intent cache directory" "$cache_tasks_file"
    assert_failure

    run grep -F -q -- "- \"{{ ovos_virtualenv_padatious_cache_dir }}\"" "$defaults_file"
    assert_success

    run grep -F -q -- "- \"{{ ovos_virtualenv_padatious_cache_staging_dir }}\"" "$defaults_file"
    assert_success

    run grep -F -q -- "- \"{{ ovos_virtualenv_padatious_cache_backup_dir }}\"" "$defaults_file"
    assert_success
}

@test "virtualenv_mark2_does_not_force_remove_phal_network_plugins" {
    local file="ansible/roles/ovos_virtualenv/tasks/venv.yml"

    run grep -q "Remove incompatible PHAL network plugins on Mark II/DevKit" "$file"
    assert_failure
}

@test "mark2_wireplumber_tasks_deploy_profile_and_remove_legacy_lua" {
    local file="ansible/roles/ovos_hardware_mark2/tasks/wireplumber.yml"

    run grep -q "Deploy Mark 2 WirePlumber profile override" "$file"
    assert_success

    run grep -q "main.lua.d/50-alsa-config.lua" "$file"
    assert_success

    run grep -q "50-alsa-config.lua.disabled-0.5" "$file"
    assert_success

    run test -f ansible/roles/ovos_hardware_mark2/files/90-sj201-profile.conf
    assert_success
}

@test "mark2_firmware_repairs_tmp_permissions_before_apt_update" {
    local defaults_file="ansible/roles/ovos_hardware_mark2/defaults/main.yml"
    local file="ansible/roles/ovos_hardware_mark2/tasks/firmware.yml"

    run grep -q "Ensure /tmp permissions are apt-compatible" "$file"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Ensure /tmp permissions are apt-compatible\" \"$file\" | grep -q -- \"path: /tmp\""
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Ensure /tmp permissions are apt-compatible\" \"$file\" | grep -q -- \"mode: \\\"1777\\\"\""
    assert_success

    run grep -q "Install kernel headers" "$file"
    assert_success

    run grep -q "ovos_hardware_mark2_apt_cache_valid_time" "$defaults_file"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Install kernel headers\" \"$file\" | grep -q -- \"cache_valid_time: \\\"{{ ovos_hardware_mark2_apt_cache_valid_time }}\\\"\""
    assert_success
}

@test "containers_setup_checks_docker_cli_without_package_facts" {
    local defaults_file="ansible/roles/ovos_containers/defaults/main.yml"
    local vars_file="ansible/roles/ovos_containers/vars/main.yml"
    local tasks_file="ansible/roles/ovos_containers/tasks/install.yml"

    run grep -q "ovos_containers_docker_binary: docker" "$defaults_file"
    assert_success

    run grep -q "Retrieve installed packages" "$tasks_file"
    assert_failure

    run grep -Eq '(^|[[:space:]-])(ansible\.builtin\.)?package_facts:' "$tasks_file"
    assert_failure

    run grep -q "Detect Docker CLI" "$tasks_file"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Detect Docker CLI\" \"$tasks_file\" | grep -F -q -- \"{{ ovos_containers_docker_binary }}\""
    assert_success

    run grep -q "ovos_containers_docker_package_check_debian" "$vars_file"
    assert_failure
}

@test "containers_git_refresh_and_compose_retry_budget_are_configurable" {
    local defaults_file="ansible/roles/ovos_containers/defaults/main.yml"
    local common_file="ansible/roles/ovos_containers/tasks/common.yml"
    local composer_file="ansible/roles/ovos_containers/tasks/composer.yml"
    local uninstall_file="ansible/roles/ovos_containers/tasks/uninstall.yml"

    run grep -q "ovos_containers_repo_force_sync" "$defaults_file"
    assert_success

    run grep -q "ovos_containers_repo_refresh_interval" "$defaults_file"
    assert_success

    run grep -q "ovos_containers_compose_retries" "$defaults_file"
    assert_success

    run grep -q "ovos_containers_compose_retry_delay" "$defaults_file"
    assert_success

    run grep -q "ovos_containers_compose_timeout" "$defaults_file"
    assert_success

    run grep -q 'ovos_installer_docker_compose_timeout | default(30)' "$defaults_file"
    assert_success

    run grep -q "Check containers repository refresh markers" "$common_file"
    assert_success

    run grep -q "_repo_update_required" "$common_file"
    assert_success

    run grep -q "update: \"{{ _repo_update_required | bool }}\"" "$common_file"
    assert_success

    run grep -q "retries: \"{{ ovos_containers_compose_retries | int }}\"" "$composer_file"
    assert_success

    run grep -q "delay: \"{{ ovos_containers_compose_retry_delay | int }}\"" "$composer_file"
    assert_success

    run grep -q 'timeout: "{{ ovos_containers_compose_timeout }}"' "$uninstall_file"
    assert_success
}

@test "containers_uninstall_uses_repo_specific_compose_directories" {
    local defaults_file="ansible/roles/ovos_containers/defaults/main.yml"
    local uninstall_file="ansible/roles/ovos_containers/tasks/uninstall.yml"

    run grep -q "ovos_containers_composition_directory_ovos" "$defaults_file"
    assert_success

    run grep -q "ovos_containers_composition_directory_hivemind" "$defaults_file"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Remove docker-compose OVOS stack(s)\" \"$uninstall_file\" | grep -q -- \"project_src: \\\"{{ ovos_containers_composition_directory_ovos }}\\\"\""
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Remove docker-compose HiveMind stack(s)\" \"$uninstall_file\" | grep -q -- \"project_src: \\\"{{ ovos_containers_composition_directory_hivemind }}\\\"\""
    assert_success
}

@test "gui_and_mark2_git_refresh_are_throttled" {
    local venv_defaults_file="ansible/roles/ovos_virtualenv/defaults/main.yml"
    local gui_tasks_file="ansible/roles/ovos_virtualenv/tasks/gui.yml"
    local mark2_defaults_file="ansible/roles/ovos_hardware_mark2/defaults/main.yml"
    local mark2_vocalfusion_file="ansible/roles/ovos_hardware_mark2/tasks/vocalfusion.yml"

    run grep -q "ovos_virtualenv_gui_repo_refresh_interval" "$venv_defaults_file"
    assert_success

    run grep -q "ovos_virtualenv_gui_repo_force_sync" "$venv_defaults_file"
    assert_success

    run grep -q "Check GUI repository refresh markers" "$gui_tasks_file"
    assert_success

    run grep -q "_gui_repo_update_required" "$gui_tasks_file"
    assert_success

    run grep -q "update: \"{{ _gui_repo_update_required | bool }}\"" "$gui_tasks_file"
    assert_success

    run grep -q "ovos_hardware_mark2_vocalfusion_repo_force_sync" "$mark2_defaults_file"
    assert_success

    run grep -q "ovos_hardware_mark2_vocalfusion_repo_refresh_interval" "$mark2_defaults_file"
    assert_success

    run grep -q "Check VocalFusion repository refresh marker" "$mark2_vocalfusion_file"
    assert_success

    run grep -q "update: \"{{ ovos_hardware_mark2_vocalfusion_repo_update | bool }}\"" "$mark2_vocalfusion_file"
    assert_success
}

@test "mark2_role_stops_install_flow_while_cleaning" {
    local defaults_file="ansible/roles/ovos_hardware_mark2/defaults/main.yml"
    local tasks_file="ansible/roles/ovos_hardware_mark2/tasks/main.yml"

    run grep -q "ovos_hardware_mark2_is_cleaning" "$defaults_file"
    assert_success

    run grep -q "Stop Mark 2 install flow while cleaning" "$tasks_file"
    assert_failure

    run grep -F -q "ansible.builtin.import_tasks: install.yml" "$tasks_file"
    assert_success

    run grep -F -q "when: not (ovos_hardware_mark2_is_cleaning | bool)" "$tasks_file"
    assert_success
}

@test "roles_use_ansible_core_2_17_compatible_cleaning_flow" {
    run grep -R -nE "(^|[[:space:]-])(ansible\\.builtin\\.)?meta:[[:space:]]*end_role([[:space:]]|$)" ansible/roles
    assert_failure
}

@test "install_bats_helpers_pins_helper_refs" {
    local script_file=".github/scripts/install_bats_helpers.sh"

    run grep -F -q 'BATS_SUPPORT_REF' "$script_file"
    assert_success

    run grep -F -q 'BATS_ASSERT_REF' "$script_file"
    assert_success

    run grep -F -q -- '--branch "$bats_support_ref"' "$script_file"
    assert_success

    run grep -F -q -- '--branch "$bats_assert_ref"' "$script_file"
    assert_success
}

@test "virtualenv_uninstall_uses_shared_constraints_url_variable" {
    local defaults_file="ansible/roles/ovos_virtualenv/defaults/main.yml"
    local uninstall_file="ansible/roles/ovos_virtualenv/tasks/uninstall.yml"

    run grep -q "ovos_virtualenv_constraints_url" "$defaults_file"
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Remove OVOS constraints from venv activation\" \"$uninstall_file\" | grep -F -q -- \"_ovos_release: \\\"{{ ovos_virtualenv_constraints_url }}\\\"\""
    assert_success
}

@test "performance_tuning_eeprom_gates_on_dpkg_query" {
    local defaults_file="ansible/roles/ovos_performance_tuning/defaults/main.yml"
    local tasks_file="ansible/roles/ovos_performance_tuning/tasks/eeprom.yml"

    run grep -q "ovos_performance_tuning_dpkg_query_path: /usr/bin/dpkg-query" "$defaults_file"
    assert_success

    run grep -q "Query EEPROM package install state (Debian)" "$tasks_file"
    assert_success

    run grep -Eq '(^|[[:space:]-])(ansible\.builtin\.)?package_facts:' "$tasks_file"
    assert_failure
}

@test "storage_tuning_log2ram_gates_on_dpkg_query" {
    local defaults_file="ansible/roles/ovos_storage_tuning/defaults/main.yml"
    local tasks_file="ansible/roles/ovos_storage_tuning/tasks/install.yml"

    run grep -q "ovos_storage_tuning_dpkg_query_path: /usr/bin/dpkg-query" "$defaults_file"
    assert_success

    run grep -q "Query log2ram package install state (Debian)" "$tasks_file"
    assert_success

    run grep -q "Gather package facts for log2ram" "$tasks_file"
    assert_failure

    run grep -Eq '(^|[[:space:]-])(ansible\.builtin\.)?package_facts:' "$tasks_file"
    assert_failure
}

@test "mark2_touchscreen_applies_overlay_management_to_tas5806_devices" {
    local file="ansible/roles/ovos_hardware_mark2/tasks/touchscreen.yml"

    run grep -q "Add rpi-backlight DT overlay" "$file"
    assert_success

    run bash -c "grep -A5 -F -- \"- name: Add rpi-backlight DT overlay\" \"$file\" | grep -q -- \"regexp: \\\"^dtoverlay=rpi-backlight\\$\\\"\""
    assert_success

    run grep -q "Manage touchscreen, DevKit vs Mark II" "$file"
    assert_success

    run bash -c "grep -A10 -F -- \"- name: Manage touchscreen, DevKit vs Mark II\" \"$file\" | grep -F -q -- \"'tas5806' in (ovos_installer_i2c_devices | default([]))\""
    assert_success

    run bash -c "grep -A10 -F -- \"- name: Manage touchscreen, DevKit vs Mark II\" \"$file\" | grep -q -- \"attiny1614\""
    assert_failure
}

@test "mark2_boot_config_changes_flag_reboot" {
    local touchscreen_file="ansible/roles/ovos_hardware_mark2/tasks/touchscreen.yml"
    local vocalfusion_file="ansible/roles/ovos_hardware_mark2/tasks/vocalfusion.yml"

    run bash -c "grep -A5 -F -- \"- name: Add rpi-backlight DT overlay\" \"$touchscreen_file\" | grep -q -- \"notify: Set Reboot\""
    assert_success

    run bash -c "grep -A10 -F -- \"- name: Manage touchscreen, DevKit vs Mark II\" \"$touchscreen_file\" | grep -q -- \"notify: Set Reboot\""
    assert_success

    run bash -c "grep -A15 -F -- \"- name: Copy DTBO files to boot overlays directory\" \"$vocalfusion_file\" | grep -q -- \"notify: Set Reboot\""
    assert_success

    run bash -c "grep -A10 -F -- \"- name: Manage sj201, buttons and PWM overlays\" \"$vocalfusion_file\" | grep -q -- \"notify: Set Reboot\""
    assert_success
}

@test "mark2_sj201_service_includes_sbin_in_runtime_path" {
    local defaults_file="ansible/roles/ovos_hardware_mark2/defaults/main.yml"
    local service_file="ansible/roles/ovos_hardware_mark2/templates/sj201.service.j2"

    run grep -q "ovos_hardware_mark2_sj201_runtime_path: /usr/local/bin:/usr/sbin:/usr/bin:/bin" "$defaults_file"
    assert_success

    run grep -F -q "ExecStart={{ ovos_hardware_mark2_sudo_path }} -E env PATH={{ ovos_hardware_mark2_sj201_runtime_path }}" "$service_file"
    assert_success

    run grep -F -q "ExecStartPost=/usr/bin/env PATH={{ ovos_hardware_mark2_sj201_runtime_path }}" "$service_file"
    assert_success
}

@test "uninstall_enables_package_removal_by_default" {
    run grep -q 'ovos_installer_uninstall_remove_packages: "{{ ovos_installer_is_cleaning | bool }}"' ansible/roles/ovos_installer/defaults/main.yml
    assert_success
}

@test "telemetry_uses_installer_detected_sound_fallback" {
    run grep -q "ovos_installer_sound_server" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success

    run grep -q "| trim" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success

    run grep -q "sound_server: \"{{ _telemetry_sound_server }}\"" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success

    run grep -q "display_server: \"{{ ovos_installer_display_server | default('unknown') | lower }}\"" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success

    run grep -q "ovos_telemetry_feature_llm" ansible/roles/ovos_telemetry/defaults/main.yml
    assert_success

    run grep -q "llm_feature: \"{{ ovos_telemetry_feature_llm | default(false) | bool }}\"" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success
}

@test "sound_role_never_writes_invalid_n_a_asound_defaults" {
    local defaults_file="ansible/roles/ovos_sound/defaults/main.yml"
    local tasks_file="ansible/roles/ovos_sound/tasks/install.yml"

    run grep -q "ovos_sound_supported_alsa_defaults" "$defaults_file"
    assert_success

    run grep -q "ovos_sound_mark2_default_server: pipewire" "$defaults_file"
    assert_success

    run grep -q "Resolve ALSA default backend for .asoundrc" "$tasks_file"
    assert_success

    run bash -c "grep -A14 -F -- \"- name: Resolve ALSA default backend for .asoundrc\" \"$tasks_file\" | grep -F -q -- \"ovos_sound_mark2_default_server\""
    assert_success

    run bash -c "grep -A22 -F -- \"- name: Resolve ALSA default backend for .asoundrc\" \"$tasks_file\" | grep -F -q -- \"_ovos_sound_mark2_fallback_server in ovos_sound_supported_alsa_defaults\""
    assert_success

    run bash -c "grep -A10 -F -- \"- name: Generate .asoundrc based on detected sound server (Raspberry Pi only)\" \"$tasks_file\" | grep -F -q -- \"pcm.!default {{ ovos_sound_asoundrc_server }}\""
    assert_success

    run bash -c "grep -A10 -F -- \"- name: Generate .asoundrc based on detected sound server (Raspberry Pi only)\" \"$tasks_file\" | grep -F -q -- \"ctl.!default {{ ovos_sound_asoundrc_server }}\""
    assert_success

    run bash -c "grep -A14 -F -- \"- name: Generate .asoundrc based on detected sound server (Raspberry Pi only)\" \"$tasks_file\" | grep -F -q -- \"ovos_sound_asoundrc_server | length > 0\""
    assert_success

    run grep -q "pcm.!default {{ ovos_sound_detect_sound_server.stdout }}" "$tasks_file"
    assert_failure
}

@test "sound_role_starts_sound_server_before_redetection" {
    local tasks_file="ansible/roles/ovos_sound/tasks/install.yml"

    run grep -q "Ensure PipeWire user sound services are running before detection" "$tasks_file"
    assert_success

    run grep -q "Ensure PulseAudio user sound service is running before detection" "$tasks_file"
    assert_success

    run bash -c "pipewire_line=\$(grep -n \"Ensure PipeWire user sound services are running before detection\" \"$tasks_file\" | head -n1 | cut -d: -f1); redetect_line=\$(grep -n \"Re-detect sound server\" \"$tasks_file\" | head -n1 | cut -d: -f1); [ -n \"\$pipewire_line\" ] && [ -n \"\$redetect_line\" ] && [ \"\$pipewire_line\" -lt \"\$redetect_line\" ]"
    assert_success

    run bash -c "pulseaudio_line=\$(grep -n \"Ensure PulseAudio user sound service is running before detection\" \"$tasks_file\" | head -n1 | cut -d: -f1); redetect_line=\$(grep -n \"Re-detect sound server\" \"$tasks_file\" | head -n1 | cut -d: -f1); [ -n \"\$pulseaudio_line\" ] && [ -n \"\$redetect_line\" ] && [ \"\$pulseaudio_line\" -lt \"\$redetect_line\" ]"
    assert_success
}

@test "homeassistant_settings_use_single_skill_directory" {
    run grep -q 'ovos_installer_homeassistant_skill_id: "skill-homeassistant.oscillatelabsllc"' ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_homeassistant_legacy_skill_ids" ansible/roles/ovos_installer/defaults/main.yml
    assert_failure

    run grep -q "_ovos_homeassistant_skill_id" ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q "Write Home Assistant skill settings.json" ansible/roles/ovos_config/tasks/install.yml
    assert_success
}

@test "containers_config_files_use_container_runtime_ownership" {
    local defaults_file="ansible/roles/ovos_config/defaults/main.yml"
    local tasks_file="ansible/roles/ovos_config/tasks/install.yml"

    run grep -F -q "ovos_config_container_runtime_uid: \"{{ ovos_installer_container_runtime_uid | default(1000) }}\"" "$defaults_file"
    assert_success

    run grep -F -q "ovos_config_container_runtime_gid: \"{{ ovos_installer_container_runtime_gid | default(1000) }}\"" "$defaults_file"
    assert_success

    run bash -c "grep -A6 -F -- \"ovos_config_mycroft_conf_owner:\" \"$defaults_file\" | grep -F -q -- \"else ovos_config_container_runtime_uid\""
    assert_success

    run bash -c "grep -A6 -F -- \"ovos_config_mycroft_conf_group:\" \"$defaults_file\" | grep -F -q -- \"else ovos_config_container_runtime_gid\""
    assert_success

    run grep -F -q "owner: \"{{ ovos_config_mycroft_conf_owner }}\"" "$tasks_file"
    assert_success

    run grep -F -q "group: \"{{ ovos_config_mycroft_conf_group }}\"" "$tasks_file"
    assert_success
}

@test "macos_does_not_require_systemd_user_config_paths" {
    run grep -q "ovos_config_backup_paths_common" ansible/roles/ovos_config/defaults/main.yml
    assert_success

    run grep -q "(ansible_facts.system | default('')) == 'Linux'" ansible/roles/ovos_config/defaults/main.yml
    assert_success

    run grep -F -q "enabled: \"{{ (ansible_facts.system | default('')) == 'Linux' }}\"" ansible/roles/ovos_config/defaults/main.yml
    assert_success

    run grep -F -q "/.config/systemd/user/*'] if (ansible_facts.system | default('')) == 'Linux' else []" ansible/roles/ovos_config/defaults/main.yml
    assert_success
}

@test "homeassistant_url_defaults_port_only_for_http" {
    run grep -q 'if \[ "\$proto" == "http" \]; then' tui/homeassistant.sh
    assert_success

    run grep -q 'default_port="8123"' tui/homeassistant.sh
    assert_success

    run grep -q 'if \[ -n "\$default_port" \]; then' tui/homeassistant.sh
    assert_success

    run grep -q 'if \[ "\$proto" == "https" \]; then' tui/homeassistant.sh
    assert_success

    run grep -q 'authority="\${authority%:8123}"' tui/homeassistant.sh
    assert_success

    run grep -q 'normalize_homeassistant_url()' tui/homeassistant.sh
    assert_success

    run grep -q 'HOMEASSISTANT_URL="\$(normalize_homeassistant_url "\$ha_existing_url")"' tui/homeassistant.sh
    assert_success
}

@test "llm_feature_writes_openvoiceos_persona_profile_and_secret_extra_vars" {
    run grep -q "SCENARIO_ALLOWED_FEATURES=(skills extra_skills homeassistant llm)" utils/constants.sh
    assert_success

    run grep -q "SCENARIO_ALLOWED_OPTIONS=(features channel share_telemetry share_usage_telemetry profile method uninstall raspberry_pi_tuning hivemind llm)" utils/constants.sh
    assert_success

    run grep -q "SCENARIO_ALLOWED_LLM_OPTIONS=(api_url key model persona max_tokens temperature top_p)" utils/constants.sh
    assert_success

    run grep -q '\.llm | to_entries | map(\[.key, .value\] | join("=")) | .\[]' utils/scenario.sh
    assert_success

    run grep -q "case \"\$option\" in" utils/scenario.sh
    assert_success

    run grep -q "llm)" utils/scenario.sh
    assert_success

    run grep -q "export LLM_API_URL=" utils/scenario.sh
    assert_success

    run grep -q "export LLM_API_KEY=" utils/scenario.sh
    assert_success

    run grep -q "export LLM_MODEL=" utils/scenario.sh
    assert_success

    run grep -q "export LLM_PERSONA=" utils/scenario.sh
    assert_success

    run grep -q "export LLM_MAX_TOKENS=" utils/scenario.sh
    assert_success

    run grep -q "export LLM_TEMPERATURE=" utils/scenario.sh
    assert_success

    run grep -q "export LLM_TOP_P=" utils/scenario.sh
    assert_success

    run grep -q 'ovos_installer_feature_llm=${FEATURE_LLM}' setup.sh
    assert_success

    run grep -q "HOMEASSISTANT_API_KEY=\"\${HOMEASSISTANT_API_KEY:-}\" LLM_API_KEY=\"\${LLM_API_KEY:-}\" jq -c -n" setup.sh
    assert_success

    run grep -q '\[ "\${FEATURE_LLM:-false}" == "true" \]' setup.sh
    assert_success

    run grep -q '\[ -n "\${LLM_MODEL:-}" \]' setup.sh
    assert_success

    run grep -q '\[ -n "\${LLM_PERSONA:-}" \]' setup.sh
    assert_failure

    run grep -q "ovos_installer_llm_model: \$llm_model" setup.sh
    assert_success

    run grep -q "ovos_installer_llm_max_tokens: \$llm_max_tokens" setup.sh
    assert_success

    run grep -q "ovos_installer_llm_temperature: \$llm_temperature" setup.sh
    assert_success

    run grep -q "ovos_installer_llm_top_p: \$llm_top_p" setup.sh
    assert_success

    run grep -q "ovos_installer_llm_api_key: (env.LLM_API_KEY // \"\")" setup.sh
    assert_success

    run grep -q "ovos_installer_llm_model:" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q 'ovos_installer_llm_model: ""' ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_llm_max_tokens: 300" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_llm_temperature: 0.2" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_llm_top_p: 0.1" ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -F -q "ovos_installer_llm_persona: \"Respond in the same language as the user in a plain spoken style for a voice assistant." ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_llm_model | default('') | trim | length > 0" ansible/roles/ovos_installer/tasks/assert.yml
    assert_success

    run grep -F -q "(ovos_installer_llm_max_tokens | default(300, true) | string | trim | int) > 0" ansible/roles/ovos_installer/tasks/assert.yml
    assert_success

    run grep -F -q "(ovos_installer_llm_temperature | default(0.2) | string | trim) is match('^([0-9]+([.][0-9]+)?|[.][0-9]+)$')" ansible/roles/ovos_installer/tasks/assert.yml
    assert_success

    run grep -F -q "(ovos_installer_llm_temperature | default(0.2) | float) >= 0" ansible/roles/ovos_installer/tasks/assert.yml
    assert_success

    run grep -F -q "(ovos_installer_llm_temperature | default(0.2) | float) <= 2" ansible/roles/ovos_installer/tasks/assert.yml
    assert_success

    run grep -F -q "(ovos_installer_llm_top_p | default(0.1) | string | trim) is match('^([0-9]+([.][0-9]+)?|[.][0-9]+)$')" ansible/roles/ovos_installer/tasks/assert.yml
    assert_success

    run grep -F -q "(ovos_installer_llm_top_p | default(0.1) | float) >= 0" ansible/roles/ovos_installer/tasks/assert.yml
    assert_success

    run grep -F -q "(ovos_installer_llm_top_p | default(0.1) | float) <= 1" ansible/roles/ovos_installer/tasks/assert.yml
    assert_success

    run grep -q '"persona": {' ansible/roles/ovos_config/templates/mycroft.conf.j2
    assert_success

    run grep -q '"solvers": \[' ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q '"ovos-solver-openai-plugin": {' ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q "_ovos_llm_model: \"{{ ovos_installer_llm_model | default('') | trim }}\"" ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q "_ovos_llm_max_tokens: \"{{ ovos_installer_llm_max_tokens | default(300, true) | string | trim | int }}\"" ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q "_ovos_llm_temperature: \"{{ ovos_installer_llm_temperature | default(0.2) | string | trim | float }}\"" ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q "_ovos_llm_top_p: \"{{ ovos_installer_llm_top_p | default(0.1) | string | trim | float }}\"" ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q '"model": _ovos_llm_model' ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q '"model": ovos_installer_llm_model' ansible/roles/ovos_config/tasks/install.yml
    assert_failure

    run grep -q '"system_prompt": ovos_installer_llm_persona' ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q '"max_tokens": _ovos_llm_max_tokens' ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q '"temperature": _ovos_llm_temperature' ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q '"top_p": _ovos_llm_top_p' ansible/roles/ovos_config/tasks/install.yml
    assert_success

    run grep -q '"persona": ovos_installer_llm_persona' ansible/roles/ovos_config/tasks/install.yml
    assert_failure

    run grep -q '.solvers\["ovos-solver-openai-plugin"\]\.system_prompt' tui/llm.sh
    assert_success

    run grep -F -q 'source "utils/llm_defaults.sh"' tui/llm.sh
    assert_success

    run grep -F -q 'export LLM_PERSONA="${LLM_PERSONA:-$LLM_DEFAULT_PERSONA}"' tui/llm.sh
    assert_success

    run grep -F -q 'llm_persona_default="${LLM_PERSONA:-$LLM_DEFAULT_PERSONA}"' tui/llm.sh
    assert_success

    run grep -q '.solvers\["ovos-solver-openai-plugin"\]\.max_tokens' tui/llm.sh
    assert_success

    run grep -q '.solvers\["ovos-solver-openai-plugin"\]\.temperature' tui/llm.sh
    assert_success

    run grep -q '.solvers\["ovos-solver-openai-plugin"\]\.top_p' tui/llm.sh
    assert_success

    run grep -F -q 'source "utils/llm_defaults.sh"' utils/argparse.sh
    assert_success

    run grep -F -q 'export LLM_MAX_TOKENS="${LLM_MAX_TOKENS:-$LLM_DEFAULT_MAX_TOKENS}"' utils/argparse.sh
    assert_success

    run grep -F -q 'export LLM_TEMPERATURE="${LLM_TEMPERATURE:-$LLM_DEFAULT_TEMPERATURE}"' utils/argparse.sh
    assert_success

    run grep -F -q 'export LLM_TOP_P="${LLM_TOP_P:-$LLM_DEFAULT_TOP_P}"' utils/argparse.sh
    assert_success
}

@test "macos_precise_onnx_is_cpu_guarded_in_requirements" {
    run grep -q "{% if (ovos_installer_cpu_is_capable | default(false)) | bool %}" ansible/roles/ovos_virtualenv/templates/virtualenv/core-requirements.txt.j2
    assert_success

    run grep -q "{% if (ovos_installer_cpu_is_capable | default(false)) | bool %}" ansible/roles/ovos_virtualenv/templates/virtualenv/satellite-requirements.txt.j2
    assert_success
}

@test "installer_detects_and_passes_hardware_model" {
    run grep -q "detect_hardware_model" setup.sh
    assert_success

    run grep -F -q "ovos_installer_hardware='\${HARDWARE_MODEL}'" setup.sh
    assert_success
}

@test "tui_hardware_falls_back_to_detected_model" {
    run grep -F -q 'if [ "$HARDWARE_DETECTED" == "N/A" ] && [ -n "${HARDWARE_MODEL:-}" ] && [ "$HARDWARE_MODEL" != "N/A" ]; then' tui/detection.sh
    assert_success
}

@test "tui_display_shows_EGLFS_for_headless_mark2_and_devkit" {
    run grep -q 'DISPLAY_DETECTED="${DISPLAY_SERVER^}"' tui/detection.sh
    assert_success

    run grep -q '\[ "${DISPLAY_SERVER,,}" == "eglfs" \]' tui/detection.sh
    assert_success

    run grep -q '\[ "${DISPLAY_SERVER:-N/A}" == "N/A" \] && \\' tui/detection.sh
    assert_success

    run grep -q 'DISPLAY_DETECTED="${DISPLAY_SERVER^^}"' tui/detection.sh
    assert_success
}

@test "tui_detection_locales_use_display_detected_label" {
    run grep -R -n '\${DISPLAY_SERVER\^}' tui/locales/*/detection.sh
    assert_failure

    run grep -R -n '\${DISPLAY_DETECTED:-\${DISPLAY_SERVER:-N/A}}' tui/locales/*/detection.sh
    assert_success
}

@test "existing_instance_skips_telemetry_prompts_in_tui" {
    local file="tui/main.sh"

    run grep -q '\[\[ "${EXISTING_INSTANCE:-false}" == "true" \]\]' "$file"
    assert_success

    run grep -q 'export SHARE_TELEMETRY="false"' "$file"
    assert_success

    run grep -q 'export SHARE_USAGE_TELEMETRY="false"' "$file"
    assert_success

    run grep -q "source tui/telemetry.sh" "$file"
    assert_success

    run grep -q "source tui/usage_telemetry.sh" "$file"
    assert_success
}

@test "setup_forces_telemetry_off_for_existing_instance" {
    local file="setup.sh"

    run grep -q 'if \[ "\$EXISTING_INSTANCE" == "true" \]; then' "$file"
    assert_success

    run grep -q 'export SHARE_TELEMETRY="false"' "$file"
    assert_success

    run grep -q 'export SHARE_USAGE_TELEMETRY="false"' "$file"
    assert_success
}

@test "telemetry_uses_existing_hardware_field_with_installer_fallback" {
    run grep -q "ovos_installer_hardware" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success

    run grep -q "hardware_model:" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_failure

    run grep -q "{%- set installer_hw = ovos_installer_hardware | default('n/a', true) | string | trim -%}" ansible/roles/ovos_telemetry/tasks/main.yml
    assert_success
}

@test "timezone_role_uses_timezone_module_on_linux_and_macos" {
    run grep -q "Set system's timezone on Linux" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run bash -c "grep -A5 -F -- \"- name: Set system's timezone on Linux\" ansible/roles/ovos_timezone/tasks/main.yml | grep -q -- \"become: true\""
    assert_success

    run grep -q "community.general.timezone" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run grep -q "ansible_facts.system == 'Linux'" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run grep -q "Set system's timezone on macOS" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Set system's timezone on macOS\" ansible/roles/ovos_timezone/tasks/main.yml | grep -q -- \"become: true\""
    assert_success

    run grep -q "Set macOS auto-timezone fact" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Read macOS timed auto-timezone preference\" ansible/roles/ovos_timezone/tasks/main.yml | grep -q -- \"become: true\""
    assert_success

    run grep -q "Read macOS timezone when automatic mode is enabled" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run grep -q "Align installer timezone fact with macOS auto-timezone value" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run grep -q "Skip manual timezone change on macOS when automatic mode is enabled" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run grep -q "not (ovos_timezone_macos_auto_enabled | default(false) | bool)" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run grep -q -- "-settimezone" ansible/roles/ovos_timezone/tasks/main.yml
    assert_failure

    run grep -q "Warn when macOS timezone update did not persist" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run grep -q "Normalize timezone facts for config consumers" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success

    run grep -F -q "regex_replace('(?i)^\\\\s*time\\\\s*zone\\\\s*:\\\\s*', '')" ansible/roles/ovos_timezone/tasks/main.yml
    assert_success
}

@test "performance_tuning_applies_rpi_eeprom_updates_and_flags_reboot" {
    local main_file="ansible/roles/ovos_performance_tuning/tasks/install.yml"
    local eeprom_file="ansible/roles/ovos_performance_tuning/tasks/eeprom.yml"
    local defaults_file="ansible/roles/ovos_performance_tuning/defaults/main.yml"

    run grep -q "Include tuning/eeprom.yml" "$main_file"
    assert_success

    run grep -q "ovos_performance_tuning_rpi_eeprom_update_cmd" "$defaults_file"
    assert_success

    run grep -q "ovos_performance_tuning_rpi_eeprom_package" "$defaults_file"
    assert_success

    run grep -q "Apply Raspberry Pi EEPROM updates" "$eeprom_file"
    assert_success

    run grep -q "Query EEPROM package install state (Debian)" "$eeprom_file"
    assert_success

    run grep -Eq '(^|[[:space:]-])(ansible\.builtin\.)?package_facts:' "$eeprom_file"
    assert_failure

    run grep -q "ovos_performance_tuning_rpi_eeprom_installed" "$eeprom_file"
    assert_success

    run grep -q "regex_search(ovos_performance_tuning_rpi_eeprom_reboot_regex)" "$eeprom_file"
    assert_success

    run bash -c "awk '/changed_when: >-/{getline; print; exit}' \"$eeprom_file\" | grep -q -- \"{{\""
    assert_failure

    run grep -q "ovos_performance_tuning_rpi_eeprom_installed | default(false) | bool" "$eeprom_file"
    assert_success

    run grep -q "notify: Set Reboot" "$eeprom_file"
    assert_success
}

@test "performance_tuning_boot_and_cmdline_changes_flag_reboot" {
    local io_file="ansible/roles/ovos_performance_tuning/tasks/io.yml"
    local numa_file="ansible/roles/ovos_performance_tuning/tasks/numa.yml"

    run bash -c "grep -A8 -F -- \"- name: Manage I2C, SPI and I2S buses\" \"$io_file\" | grep -q -- \"notify: Set Reboot\""
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Disable USB Autosuspend (cmdline.txt)\" \"$io_file\" | grep -q -- \"notify: Set Reboot\""
    assert_success

    run bash -c "grep -A10 -F -- \"- name: Apply CPU boost/voltage settings (config.txt)\" \"$io_file\" | grep -q -- \"notify: Set Reboot\""
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Apply CPU frequency overclock (config.txt)\" \"$io_file\" | grep -q -- \"notify: Set Reboot\""
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Apply GPU overclocking (config.txt)\" \"$io_file\" | grep -q -- \"notify: Set Reboot\""
    assert_success

    run bash -c "grep -A14 -F -- \"- name: Enable NUMA for Raspberry Pi 4 & 5\" \"$numa_file\" | grep -q -- \"notify: Set Reboot\""
    assert_success
}

@test "services_asserts_messagebus_binary_before_starting_services" {
    run grep -q "Check OVOS messagebus binary exists" ansible/roles/ovos_services/tasks/assert.yml
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Check OVOS messagebus binary exists\" ansible/roles/ovos_services/tasks/assert.yml | grep -q -- \"follow: true\""
    assert_success

    run grep -q "Assert OVOS messagebus binary exists" ansible/roles/ovos_services/tasks/assert.yml
    assert_success

    run grep -q "path: \"{{ ovos_services_messagebus_command }}\"" ansible/roles/ovos_services/tasks/assert.yml
    assert_success
}

@test "services_messagebus_arch_platform_match_virtualenv_logic" {
    run grep -q "else 'armv7' if (ansible_facts.architecture | default('')) in \\['armv7', 'armv7l'\\]" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "else 'arm' if (ansible_facts.architecture | default('')) in \\['arm', 'armv6', 'armv6l'\\]" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "else 'unknown-linux-gnueabihf' if ovos_services_messagebus_target_arch in \\['arm', 'armv7'\\]" ansible/roles/ovos_services/defaults/main.yml
    assert_success
}

@test "listener_systemd_unit_orders_with_core_dependencies_without_prestart_gate" {
    local file="ansible/roles/ovos_services/templates/virtualenv/ovos-listener.service.j2"

    run grep -q "^Requires=ovos.service ovos-messagebus.service ovos-core.service ovos-phal.service$" "$file"
    assert_success

    run grep -q "^After=ovos.service ovos-messagebus.service ovos-core.service ovos-phal.service$" "$file"
    assert_success

    run grep -q "^ExecStartPre=" "$file"
    assert_failure

    run grep -q "^TimeoutStartSec=5min$" "$file"
    assert_success
}

@test "phal_systemd_unit_orders_with_audio_stack_for_user_and_system_scopes" {
    local file="ansible/roles/ovos_services/templates/virtualenv/ovos-phal.service.j2"

    run grep -q "^After=ovos.service ovos-messagebus.service$" "$file"
    assert_success

    run grep -q "^Wants=sound.target$" "$file"
    assert_success

    run grep -q "^After=sound.target$" "$file"
    assert_success

    run grep -F -q "{% set _ovos_sound_server = (ovos_installer_sound_server | default('N/A')) | lower %}" "$file"
    assert_success

    run grep -F -q "{% if _ovos_sound_server == 'pipewire' %}" "$file"
    assert_success

    run grep -q "^Wants=pipewire.service wireplumber.service$" "$file"
    assert_success

    run grep -q "^After=pipewire.service wireplumber.service$" "$file"
    assert_success

    run grep -F -q "{% elif _ovos_sound_server == 'pulseaudio' %}" "$file"
    assert_success

    run grep -q "^Wants=pulseaudio.service$" "$file"
    assert_success

    run grep -q "^After=pulseaudio.service$" "$file"
    assert_success

    run grep -F -q "{% if ansible_facts.system != 'Darwin' and ((ovos_installer_sound_server | default('N/A')) | lower) == 'pipewire' %}" "$file"
    assert_success

    run grep -F -q "ExecStartPre=/bin/bash -c 'for _ovos_retry in {1..30}; do [ -S /run/user/{{ ovos_installer_uid }}/pipewire-0 ] && exit 0; sleep 1; done; echo \"PipeWire socket unavailable: /run/user/{{ ovos_installer_uid }}/pipewire-0\" >&2; exit 1'" "$file"
    assert_success
}

@test "gui_systemd_units_have_ordering_and_no_venv_workdir" {
    run grep -q "^After=ovos.service ovos-messagebus.service$" ansible/roles/ovos_services/templates/virtualenv/ovos-gui-websocket.service.j2
    assert_success

    run grep -q "^After=ovos.service ovos-gui-websocket.service ovos-phal.service$" ansible/roles/ovos_services/templates/virtualenv/ovos-gui.service.j2
    assert_success

    run grep -q "_ovos_headless_display = (ovos_installer_display_server | default('') | lower) in \\['n/a', 'eglfs'\\]" ansible/roles/ovos_services/templates/virtualenv/ovos-gui.service.j2
    assert_success

    run grep -q "QT_QPA_PLATFORM={{ 'eglfs' if _ovos_headless_display else 'wayland;xcb' }}" ansible/roles/ovos_services/templates/virtualenv/ovos-gui.service.j2
    assert_success

    run grep -q "{{ 'ovos-shell' if _ovos_headless_display else 'ovos-gui-app' }}" ansible/roles/ovos_services/templates/virtualenv/ovos-gui.service.j2
    assert_success

    run grep -q "^WorkingDirectory=.*\\.venvs/ovos$" ansible/roles/ovos_services/templates/virtualenv/ovos-gui.service.j2
    assert_failure
}

@test "virtualenv_systemd_units_do_not_force_kill_on_stop" {
    run rg -n 'ExecStop=/usr/bin/kill -s KILL \\$MAINPID' ansible/roles/ovos_services/templates/virtualenv
    assert_failure
}

@test "setup_exports_collection_paths_for_launchd_module_resolution" {
    run grep -q "ANSIBLE_COLLECTIONS_PATH" setup.sh
    assert_success

    run grep -F -q '${PWD}/.ansible/collections' setup.sh
    assert_success

    run grep -q "/var/root/.ansible/collections" setup.sh
    assert_success
}

@test "services_uninstall_uses_correct_dropin_directory_paths" {
    local file="ansible/roles/ovos_services/tasks/uninstall.yml"

    run grep -F -q 'path: "{{ ovos_installer_systemd_system_path }}/{{ item }}.d"' "$file"
    assert_success

    run grep -F -q 'path: "{{ ovos_installer_systemd_user_path }}/{{ item }}.d"' "$file"
    assert_success

    run grep -q '\.service\.d' "$file"
    assert_failure
}

@test "install_ansible_installs_collections_to_repo_local_path" {
    run grep -F -q 'collections_path="${PWD}/.ansible/collections"' utils/common.sh
    assert_success

    run grep -F -q -- '--collections-path "$collections_path"' utils/common.sh
    assert_success
}

@test "install_ansible_reuses_collections_cache_when_enabled" {
    run grep -F -q 'collections_stamp="${collections_path}/.requirements.checksum"' utils/common.sh
    assert_success

    run grep -F -q 'if [ "${REUSE_CACHED_ARTIFACTS:-false}" == "true" ] && [ -f "$collections_stamp" ]; then' utils/common.sh
    assert_success

    run grep -F -q 'required_collections_present "$collections_path" "$requirements_file"' utils/common.sh
    assert_success
}

@test "install_ansible_reuses_python_packages_when_enabled" {
    run grep -F -q 'python_packages_match_versions "$VENV_PATH/bin/python3" "${ansible_packages[@]}"' utils/common.sh
    assert_success

    run grep -F -q '[info] Reusing cached ansible python packages from ${VENV_PATH}' utils/common.sh
    assert_success
}

@test "create_python_venv_reuses_cached_virtualenv_when_valid" {
    run grep -F -q "function installer_venv_is_reusable()" utils/common.sh
    assert_success

    run grep -F -q 'if [ "$reuse_cached_artifacts" == "true" ] && installer_venv_is_reusable "$VENV_PATH" "$PYTHON"; then' utils/common.sh
    assert_success

    run grep -F -q "function python_version_major_minor()" utils/common.sh
    assert_success

    run grep -F -q 'local venv_python_cmd="${PYTHON_CMD:-python3}"' utils/common.sh
    assert_success

    run grep -F -q '"$venv_python_cmd" -m venv "$VENV_PATH"' utils/common.sh
    assert_success

    run grep -F -q 'if [ "$venv_reused" != "true" ]; then' utils/common.sh
    assert_success
}

@test "create_python_venv_bootstrap_installs_are_cache_aware" {
    run grep -F -q 'run_with_errexit_guard pip3 install "uv>=0.4.10"' utils/common.sh
    assert_success

    run grep -F -q 'run_with_errexit_guard pip3 install --no-cache-dir "uv>=0.4.10"' utils/common.sh
    assert_success

    run grep -F -q '$PIP_COMMAND install --upgrade pip setuptools' utils/common.sh
    assert_success
}

@test "installer_uses_temporary_pip_config_override_instead_of_mutating_etc_pip_conf" {
    run grep -F -q "function prepare_installer_pip_config()" utils/common.sh
    assert_success

    run grep -F -q 'ovos_installer_pip_config_file=${PIP_CONFIG_FILE:-}' setup.sh
    assert_success

    run grep -q "PIP_CONFIG_FILE" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "Restore /etc/pip.conf configuration" ansible/roles/ovos_finalize/tasks/main.yml
    assert_failure

    run grep -F -q "sed -e '/extra-index/ s/^#*/#/g' -i /etc/pip.conf" utils/common.sh
    assert_failure

    run grep -F -q 'if [ "${ARCH:-}" != "aarch64" ]; then' utils/common.sh
    assert_success

    run grep -F -q 'RASPBERRYPI_MODEL:-}" != *"Raspberry Pi 5"*' utils/common.sh
    assert_failure
}

@test "setup_downloads_yq_only_when_scenario_file_exists" {
    run grep -F -q "detect_scenario" setup.sh
    assert_success

    run grep -Eq "^[[:space:]]*download_yq([[:space:]]|$)" setup.sh
    assert_failure
}

@test "setup_uses_runtime_lock_and_signal_cleanup_hooks" {
    run grep -F -q "acquire_installer_lock" setup.sh
    assert_success

    run grep -F -q "trap cleanup_installer_runtime EXIT" setup.sh
    assert_success

    run grep -F -q "trap 'exit_with_signal_code 130' INT" setup.sh
    assert_success

    run grep -F -q "trap 'exit_with_signal_code 143' TERM" setup.sh
    assert_success
}

@test "setup_keeps_ansible_color_in_terminal_and_plain_text_in_logs" {
    run grep -F -q "function strip_ansi_stream()" utils/common.sh
    assert_success

    run grep -F -q "if [ -t 1 ]; then" setup.sh
    assert_success

    run bash -c "grep -A4 -F -- \"if [ -t 1 ]; then\" setup.sh | grep -F -q -- \"export ANSIBLE_FORCE_COLOR=true\""
    assert_success

    run bash -c "grep -A4 -F -- \"if [ -t 1 ]; then\" setup.sh | grep -F -q -- \"export PY_COLORS=1\""
    assert_success

    run bash -c "grep -A4 -F -- \"if [ -t 1 ]; then\" setup.sh | grep -F -q -- \"unset ANSIBLE_NOCOLOR || true\""
    assert_success

    run grep -F -q "export ANSIBLE_NOCOLOR=true" setup.sh
    assert_success

    run grep -F -q 'mkfifo "$ansi_log_pipe"' setup.sh
    assert_success

    run grep -F -q 'tee -a "$LOG_FILE"' setup.sh
    assert_success

    run grep -F -q 'pipeline_status=("${PIPESTATUS[@]}")' setup.sh
    assert_success

    run grep -F -q 'tee_rc="${pipeline_status[1]}"' setup.sh
    assert_success

    run grep -F -q 'wait "$ansi_log_pipe_pid" || strip_rc="$?"' setup.sh
    assert_success

    run grep -F -q 'log_error "Failed to write Ansible output to $LOG_FILE."' setup.sh
    assert_success
}

@test "common_defines_installer_lock_and_cleanup_helpers" {
    run grep -F -q "function acquire_installer_lock()" utils/common.sh
    assert_success

    run grep -F -q "function release_installer_lock()" utils/common.sh
    assert_success

    run grep -F -q "function cleanup_installer_runtime()" utils/common.sh
    assert_success

    run grep -F -q "function exit_with_signal_code()" utils/common.sh
    assert_success
}

@test "scenario_validation_checks_required_keys_explicitly" {
    local file="utils/scenario.sh"

    run grep -q "declare -a required_options=(" "$file"
    assert_success

    run grep -q "share_usage_telemetry" "$file"
    assert_success

    run grep -q 'for required_option in "\${required_options\[@\]}"; do' "$file"
    assert_success

    run grep -q '\${options\[\$required_option\]+x}' "$file"
    assert_success

    run grep -q '\-lt 7' "$file"
    assert_failure
}

@test "detect_existing_instance_uses_runtime_helper" {
    run grep -F -q "function container_runtime_has_ovos_instance()" utils/common.sh
    assert_success

    run grep -F -q 'container_runtime_has_ovos_instance docker "Docker" "$name_regex"' utils/common.sh
    assert_success

    run grep -F -q 'container_runtime_has_ovos_instance podman "Podman" "$name_regex"' utils/common.sh
    assert_success
}

@test "launchd_module_uses_plist_basename_not_absolute_path" {
    run grep -q "ovos_services_launchd_plist_name: \"{{ item.label }}.plist\"" ansible/roles/ovos_services/tasks/launchd.yml
    assert_success

    run grep -q "ovos_services_legacy_plist_name: \"{{ item.item }}.plist\"" ansible/roles/ovos_services/tasks/launchd.yml
    assert_success

    run grep -q "plist: \"{{ ovos_services_launchd_plist_name }}\"" ansible/roles/ovos_services/tasks/launchd.yml
    assert_success

    run grep -q "ovos_services_launchd_plist_name: \"{{ item.label }}.plist\"" ansible/roles/ovos_services/handlers/main.yml
    assert_success

    run grep -q "ovos_services_launchd_plist_name: \"{{ item.label }}.plist\"" ansible/roles/ovos_services/tasks/uninstall-launchd.yml
    assert_success

    run grep -q "ovos_services_launchd_plist_name: \"{{ item.item }}.plist\"" ansible/roles/ovos_services/tasks/uninstall-launchd.yml
    assert_success

    run grep -q "plist: \"{{ ovos_services_launchd_plist_name }}\"" ansible/roles/ovos_services/handlers/main.yml
    assert_success

    run grep -q "plist: \"{{ ovos_services_launchd_plist_name }}\"" ansible/roles/ovos_services/tasks/uninstall-launchd.yml
    assert_success

    run grep -q "plist: \"{{ ovos_services_launchd_agents_path }}/{{ item.label }}.plist\"" ansible/roles/ovos_services/tasks/launchd.yml
    assert_failure
}

@test "launchd_uninstall_uses_collection_module" {
    run grep -q "community.general.launchd" ansible/roles/ovos_services/tasks/uninstall-launchd.yml
    assert_success

    run grep -q "/bin/launchctl" ansible/roles/ovos_services/tasks/uninstall-launchd.yml
    assert_failure
}

@test "launchd_install_uses_collection_module_only" {
    run grep -q "community.general.launchd" ansible/roles/ovos_services/tasks/launchd.yml
    assert_success

    run grep -q "launchctl" ansible/roles/ovos_services/tasks/launchd.yml
    assert_failure
}

@test "launchd_install_system_path_tasks_use_privilege_escalation" {
    run bash -c "grep -A8 -F -- \"- name: Copy wrapper-ovos-phal-admin.sh file\" ansible/roles/ovos_services/tasks/launchd.yml | grep -q -- \"become: true\""
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Ensure launchd system daemons directory exists\" ansible/roles/ovos_services/tasks/launchd.yml | grep -q -- \"become: true\""
    assert_success

    run bash -c "grep -A10 -F -- \"- name: Copy OVOS launchd plist files\" ansible/roles/ovos_services/tasks/launchd.yml | grep -q -- \"become: true\""
    assert_success
}

@test "launchd_uninstall_removes_plists_with_privilege_escalation" {
    run bash -c "grep -A4 -F -- \"- name: Remove OVOS launchd plist files\" ansible/roles/ovos_services/tasks/uninstall-launchd.yml | grep -q -- \"become: true\""
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Remove legacy OVOS core launchd plist files\" ansible/roles/ovos_services/tasks/uninstall-launchd.yml | grep -q -- \"become: true\""
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Remove wrapper script\" ansible/roles/ovos_services/tasks/uninstall-launchd.yml | grep -q -- \"become: true\""
    assert_success
}

@test "launchd_user_operations_use_configurable_execution_mode" {
    run grep -q "ovos_services_launchd_user_management_mode: user" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "ovos_services_launchd_user_module_become_user" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "ovos_services_launchd_user_lookup_environment" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "ovos_services_launchd_user_module_environment" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "ovos_services_launchd_user_management_mode in \\['root', 'user'\\]" ansible/roles/ovos_services/tasks/assert.yml
    assert_success

    run bash -c "grep -A18 -F -- \"- name: Ensure OVOS launchd user services are enabled and loaded\" ansible/roles/ovos_services/tasks/launchd.yml | grep -q -- \"become_user: \\\"{{ ovos_services_launchd_user_module_become_user }}\\\"\""
    assert_success

    run bash -c "grep -A18 -F -- \"- name: Ensure OVOS launchd user services are enabled and loaded\" ansible/roles/ovos_services/tasks/launchd.yml | grep -q -- \"ovos_services_launchd_user_module_environment\""
    assert_success

    run bash -c "grep -A18 -F -- \"- name: Disable and unload OVOS launchd user services\" ansible/roles/ovos_services/tasks/uninstall-launchd.yml | grep -q -- \"become_user: \\\"{{ ovos_services_launchd_user_module_become_user }}\\\"\""
    assert_success

    run bash -c "grep -A18 -F -- \"- name: Restart OVOS services (launchd user)\" ansible/roles/ovos_services/handlers/main.yml | grep -q -- \"become_user: \\\"{{ ovos_services_launchd_user_module_become_user }}\\\"\""
    assert_success

    run bash -c "grep -A18 -F -- \"- name: Restart OVOS services (launchd user)\" ansible/roles/ovos_services/handlers/main.yml | grep -q -- \"ovos_services_launchd_user_module_environment\""
    assert_success
}

@test "services_repair_runtime_directory_ownership_on_install" {
    run grep -q "ovos_services_user_runtime_dirs" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "ovos_services_launchd_log_dir" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "Ensure user cache root directory exists with correct ownership" ansible/roles/ovos_services/tasks/install.yml
    assert_success

    run grep -q "/.cache" ansible/roles/ovos_services/tasks/install.yml
    assert_success

    run grep -q "/.cache/huggingface" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "/.cache/OCP" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "Ensure OVOS runtime user directories exist" ansible/roles/ovos_services/tasks/install.yml
    assert_success

    run grep -q "Ensure OVOS runtime user directory ownership is corrected recursively" ansible/roles/ovos_services/tasks/install.yml
    assert_success

    run grep -q "recurse: true" ansible/roles/ovos_services/tasks/install.yml
    assert_success
}

@test "services_user_scope_operations_export_user_bus_environment" {
    local systemd_file="ansible/roles/ovos_services/tasks/systemd.yml"
    local uninstall_file="ansible/roles/ovos_services/tasks/uninstall.yml"

    run grep -q "ovos_services_user_bus_environment" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "Ensure systemd user runtime is available" "$systemd_file"
    assert_success

    run grep -q "systemd-user-runtime.yml" "$uninstall_file"
    assert_success

    run grep -q 'environment: "{{ ovos_services_user_bus_environment }}"' ansible/roles/ovos_services/handlers/main.yml
    assert_success

    run grep -q 'environment: "{{ ovos_services_user_bus_environment }}"' ansible/roles/ovos_services/handlers/block-sound.yml
    assert_success

    run grep -q 'environment: "{{ ovos_services_user_bus_environment }}"' "$systemd_file"
    assert_success

    run grep -q 'environment: "{{ ovos_services_user_bus_environment }}"' "$uninstall_file"
    assert_success
}

@test "services_user_runtime_setup_precedes_user_scope_cleanup_and_uninstall_skips_linger_changes" {
    local systemd_file="ansible/roles/ovos_services/tasks/systemd.yml"
    local uninstall_file="ansible/roles/ovos_services/tasks/uninstall.yml"

    run bash -c 'runtime_line=$(grep -n "systemd-user-runtime.yml" "$1" | head -n1 | cut -d: -f1); cleanup_line=$(grep -n "Stop and disable OVOS user units from previous installs" "$1" | head -n1 | cut -d: -f1); [ -n "$runtime_line" ] && [ -n "$cleanup_line" ] && [ "$runtime_line" -lt "$cleanup_line" ]' _ "$systemd_file"
    assert_success

    run grep -q "ovos_services_manage_linger: false" "$uninstall_file"
    assert_success

    run grep -q "show-user" "$uninstall_file"
    assert_failure

    run grep -q "Disable lingering if uninstall enabled it temporarily" "$uninstall_file"
    assert_failure

    run grep -q "ovos_services_disable_linger_cmd" ansible/roles/ovos_services/defaults/main.yml
    assert_failure
}

@test "services_uninstall_removes_requested_runtime_artifacts" {
    local defaults_file="ansible/roles/ovos_services/defaults/main.yml"

    run grep -F -q "{{ ovos_installer_user_home }}/.config/wireplumber/wireplumber.conf.d/90-sj201-profile.conf" "$defaults_file"
    assert_success

    run grep -F -q "{{ ovos_installer_user_home }}/.local/state/mycroft-persistent" "$defaults_file"
    assert_success

    run grep -F -q "{{ ovos_installer_user_home }}/.local/share/vosk" "$defaults_file"
    assert_success

    run grep -F -q "{{ ovos_installer_user_home }}/.local/share/precise-onnx" "$defaults_file"
    assert_success

    run grep -F -q "{{ ovos_installer_user_home }}/.local/share/wallpapers" "$defaults_file"
    assert_success

    run grep -F -q "{{ ovos_installer_user_home }}/.cache/huggingface" "$defaults_file"
    assert_success

    run grep -F -q "{{ ovos_installer_user_home }}/.cache/OpenVoiceOS" "$defaults_file"
    assert_success

    run grep -F -q "{{ ovos_installer_user_home }}/.cache/ovos-installer" "$defaults_file"
    assert_success

    run grep -F -q "{{ ovos_installer_user_home }}/.ovos-installer" "$defaults_file"
    assert_success
}

@test "launchd_system_scope_uses_root_cache_home" {
    run grep -q "'/var/root' if item.scope == 'system'" ansible/roles/ovos_services/templates/launchd/service.plist.j2
    assert_success

    run grep -q "'/var/root/.cache' if item.scope == 'system'" ansible/roles/ovos_services/templates/launchd/service.plist.j2
    assert_success

    run grep -q "'/var/root/.config' if item.scope == 'system'" ansible/roles/ovos_services/templates/launchd/service.plist.j2
    assert_success
}

@test "launchd_template_omits_empty_extra_environment_entries" {
    run grep -q "_ovos_launchd_env_value = env_value | string | trim" ansible/roles/ovos_services/templates/launchd/service.plist.j2
    assert_success

    run grep -q "_ovos_launchd_env_value | length" ansible/roles/ovos_services/templates/launchd/service.plist.j2
    assert_success
}

@test "launchd_shell_wrapper_is_installed_and_removed_cleanly" {
    run test -f ansible/roles/ovos_services/templates/launchd/ovos-launchd.zsh.j2
    assert_success

    run grep -q "ovos_services_launchd_wrapper_template" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "ovos_services_launchd_wrapper_path" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "ovos_services_launchd_shell_init_file" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "Install OVOS launchd zsh wrapper" ansible/roles/ovos_services/tasks/launchd.yml
    assert_success

    run grep -q "Ensure zsh sources OVOS launchd wrapper" ansible/roles/ovos_services/tasks/launchd.yml
    assert_success

    run grep -q "ovos_services_launchd_shell_marker" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "ovos_services_launchd_shell_marker" ansible/roles/ovos_services/tasks/launchd.yml
    assert_success

    run grep -q "Remove OVOS launchd wrapper source block from shell init file" ansible/roles/ovos_services/tasks/uninstall-launchd.yml
    assert_success

    run grep -q "Remove OVOS launchd shell wrapper" ansible/roles/ovos_services/tasks/uninstall-launchd.yml
    assert_success

    run grep -q "ovos() {" ansible/roles/ovos_services/templates/launchd/ovos-launchd.zsh.j2
    assert_success

    run grep -q "start|stop|restart|status" ansible/roles/ovos_services/templates/launchd/ovos-launchd.zsh.j2
    assert_success
}

@test "launchd_keepalive_restarts_on_failure" {
    run grep -q "ovos_services_launchd_restart_on_failure: true" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "ovos_services_launchd_restart_on_failure" ansible/roles/ovos_services/templates/launchd/service.plist.j2
    assert_success

    run grep -q "{% if ovos_services_launchd_restart_on_failure | default(true) | bool %}" ansible/roles/ovos_services/templates/launchd/service.plist.j2
    assert_success

    run grep -q "{% elif ovos_services_launchd_keep_alive | bool %}" ansible/roles/ovos_services/templates/launchd/service.plist.j2
    assert_success

    run grep -q "<key>SuccessfulExit</key>" ansible/roles/ovos_services/templates/launchd/service.plist.j2
    assert_success

    run grep -q "<false/>" ansible/roles/ovos_services/templates/launchd/service.plist.j2
    assert_success
}

@test "mycroft_conf_sanitizes_timezone_prefix" {
    run grep -F -q "regex_replace('(?i)^\\\\s*time\\\\s*zone\\\\s*:\\\\s*', '')" ansible/roles/ovos_config/templates/mycroft.conf.j2
    assert_success
}

@test "macos_cpu_detection_queries_leaf7_only_on_intel" {
    run grep -q 'machine_arch="$(uname -m' utils/common.sh
    assert_success

    run grep -q 'if \[ "\$machine_arch" = "x86_64" \] && sysctl -n machdep.cpu.leaf7_features' utils/common.sh
    assert_success
}

@test "macos_scenario_smoke_runs_on_intel_and_arm" {
    run grep -F -q "macos-scenario-matrix:" .github/workflows/macos_ci.yml
    assert_success

    run grep -F -q "runs-on: \${{ matrix.runner }}" .github/workflows/macos_ci.yml
    assert_success

    run grep -E -q -- "- macos-[0-9]+-intel" .github/workflows/macos_ci.yml
    assert_success

    run grep -E -q -- "- macos-[0-9]+$" .github/workflows/macos_ci.yml
    assert_success
}

@test "workflows_enable_concurrency_cancel_in_progress" {
    run grep -F -q "cancel-in-progress: true" .github/workflows/linting.yml
    assert_success

    run grep -F -q "cancel-in-progress: true" .github/workflows/macos_ci.yml
    assert_success

    run grep -F -q "cancel-in-progress: true" .github/workflows/shell_testing.yml
    assert_success

    run grep -F -q "cancel-in-progress: true" .github/workflows/scenarios-ubuntu2404.yml
    assert_success
}

@test "ci_uses_profile_tasks_callback_and_runtime_thresholds" {
    run grep -F -q "ANSIBLE_CALLBACKS_ENABLED=\"profile_tasks,timer\"" .github/workflows/macos_ci.yml
    assert_success

    run grep -F -q "OVOS_CI_MAX_INSTALL_SECONDS" .github/workflows/macos_ci.yml
    assert_success

    run grep -F -q "ANSIBLE_CALLBACKS_ENABLED=\"profile_tasks,timer\"" .github/workflows/scenarios-ubuntu2404.yml
    assert_success

    run grep -F -q "OVOS_CI_MAX_INSTALL_SECONDS" .github/workflows/scenarios-ubuntu2404.yml
    assert_success
}

@test "ci_restores_python_uv_and_collection_caches" {
    run grep -F -q "uses: actions/cache@v5.0.3" .github/workflows/linting.yml
    assert_success

    run grep -F -q "~/.cache/uv" .github/workflows/linting.yml
    assert_success

    run grep -F -q "~/.ansible/collections" .github/workflows/macos_ci.yml
    assert_success

    run grep -F -q "~/.ovos-installer/uv-cache" .github/workflows/scenarios-ubuntu2404.yml
    assert_success
}

function teardown() {
    rm -f "$LOG_FILE"
    if [ -n "$DETECT_SOUND_BACKUP" ]; then
        cp "$DETECT_SOUND_BACKUP" "utils/detect_sound.py"
        rm -f "$DETECT_SOUND_BACKUP"
    else
        rm -f "utils/detect_sound.py"
    fi
    unset RUN_AS RUN_AS_UID SUDO_USER SUDO_UID USER_ID SOUND_SERVER
}

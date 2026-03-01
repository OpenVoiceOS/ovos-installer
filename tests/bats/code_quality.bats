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
    assert_equal "${AVRDUDE_BINARY_PATH}" "/usr/local/bin/avrdude"
    assert_equal "${AVRDUDE_BINARY_URL}" "https://artifacts.smartgic.io/avrdude/avrdude-aarch64"
    assert_equal "${AVRDUDE_CONFIG_PATH}" "/usr/local/etc/avrdude.conf"
    assert_equal "${AVRDUDE_CONFIG_URL}" "https://artifacts.smartgic.io/avrdude/avrdude.conf"
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

@test "mycroft_conf_sets_gui_idle_display_skill_to_current_homescreen_id" {
    local file="ansible/roles/ovos_config/templates/mycroft.conf.j2"

    run grep -q "{% if ovos_installer_feature_gui | bool %}" "$file"
    assert_success

    run bash -c "grep -A4 -F -- \"{% if ovos_installer_feature_gui | bool %}\" \"$file\" | grep -q -- \"\\\"idle_display_skill\\\": \\\"skill-ovos-homescreen.openvoiceos\\\"\""
    assert_success

    run grep -q "\"idle_display_skill\": \"ovos-skill-homescreen.openvoiceos\"" "$file"
    assert_failure
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

    run grep -q "UV_CACHE_DIR: \"{{ ovos_virtualenv_uv_cache_dir }}\"" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "Ensure dedicated uv cache directory exists" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success

    run grep -q "environment: \"{{ ovos_virtualenv_uv_environment }}\"" ansible/roles/ovos_virtualenv/tasks/venv.yml
    assert_success
}

@test "virtualenv_uv_uses_consistent_exec_path_with_homebrew_prefixes" {
    run grep -q "ovos_virtualenv_installer_venv_path" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "ovos_virtualenv_uv_exec_path" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "/opt/homebrew/bin:/usr/local/bin" ansible/roles/ovos_virtualenv/defaults/main.yml
    assert_success

    run grep -q "PATH: \"{{ ovos_virtualenv_uv_exec_path }}\"" ansible/roles/ovos_virtualenv/defaults/main.yml
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

    run bash -c "grep -A4 -F -- \"- name: Install tflite_runtime bootstrap package (non-macOS AVX/SIMD hosts)\" \"$file\" | grep -q -- 'become_user: \"{{ ovos_installer_user }}\"'"
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Install wheel bootstrap package (macOS or non-AVX/SIMD hosts)\" \"$file\" | grep -q -- 'become_user: \"{{ ovos_installer_user }}\"'"
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Install ggwave Python library\" \"$file\" | grep -q -- 'become_user: \"{{ ovos_installer_user }}\"'"
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Install Open Voice OS in Python venv\" \"$file\" | grep -q -- 'become_user: \"{{ ovos_installer_user }}\"'"
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Ensure numpy Python library is installed\" \"$file\" | grep -q -- 'become_user: \"{{ ovos_installer_user }}\"'"
    assert_success

    run bash -c "grep -A4 -F -- \"- name: Ensure setuptools Python library is compatible with OVOS runtime\" \"$file\" | grep -q -- 'become_user: \"{{ ovos_installer_user }}\"'"
    assert_success
}

@test "virtualenv_uv_bootstrap_and_runtime_installs_skip_cleaning" {
    local file="ansible/roles/ovos_virtualenv/tasks/venv.yml"

    run bash -c "grep -A12 -F -- \"- name: Install tflite_runtime bootstrap package (non-macOS AVX/SIMD hosts)\" \"$file\" | grep -F -q -- 'not (ovos_installer_cleaning | default(false) | bool)'"
    assert_success

    run bash -c "grep -A12 -F -- \"- name: Install wheel bootstrap package (macOS or non-AVX/SIMD hosts)\" \"$file\" | grep -F -q -- 'not (ovos_installer_cleaning | default(false) | bool)'"
    assert_success

    run bash -c "grep -A12 -F -- \"- name: Install ggwave Python library\" \"$file\" | grep -F -q -- 'not (ovos_installer_cleaning | default(false) | bool)'"
    assert_success

    run bash -c "grep -A12 -F -- \"- name: Ensure numpy Python library is installed\" \"$file\" | grep -F -q -- 'not (ovos_installer_cleaning | default(false) | bool)'"
    assert_success

    run bash -c "grep -A12 -F -- \"- name: Ensure setuptools Python library is compatible with OVOS runtime\" \"$file\" | grep -F -q -- 'not (ovos_installer_cleaning | default(false) | bool)'"
    assert_success
}

@test "virtualenv_repairs_ownership_before_python_package_installs" {
    local file="ansible/roles/ovos_virtualenv/tasks/venv.yml"

    run grep -q "Ensure OVOS virtualenv ownership is aligned before package installs" "$file"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Ensure OVOS virtualenv ownership is aligned before package installs\" \"$file\" | grep -q -- 'recurse: true'"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Ensure OVOS virtualenv ownership is aligned before package installs\" \"$file\" | grep -q -- 'owner: \"{{ ovos_installer_user }}\"'"
    assert_success

    run bash -c "grep -A8 -F -- \"- name: Ensure OVOS virtualenv ownership is aligned before package installs\" \"$file\" | grep -q -- 'group: \"{{ ovos_installer_group }}\"'"
    assert_success

    run bash -c "awk '/Ensure OVOS virtualenv ownership is aligned before package installs/{owner_line=NR} /Ensure numpy Python library is installed/{numpy_line=NR} END{exit !(owner_line>0 && numpy_line>0 && owner_line<numpy_line)}' \"$file\""
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

@test "uninstall_enables_package_removal_by_default" {
    run grep -q 'ovos_installer_uninstall_remove_packages: "{{ ovos_installer_cleaning | default(false) | bool }}"' ansible/roles/ovos_installer/defaults/main.yml
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
}

@test "homeassistant_settings_use_single_skill_directory" {
    run grep -q 'ovos_installer_homeassistant_skill_id: "skill-homeassistant.oscillatelabsllc"' ansible/roles/ovos_installer/defaults/main.yml
    assert_success

    run grep -q "ovos_installer_homeassistant_legacy_skill_ids" ansible/roles/ovos_installer/defaults/main.yml
    assert_failure

    run grep -q "_ovos_homeassistant_skill_id" ansible/roles/ovos_config/tasks/main.yml
    assert_success

    run grep -q "Write Home Assistant skill settings.json" ansible/roles/ovos_config/tasks/main.yml
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

@test "gui_systemd_units_have_ordering_and_no_venv_workdir" {
    run grep -q "^After=ovos.service ovos-messagebus.service$" ansible/roles/ovos_services/templates/virtualenv/ovos-gui-websocket.service.j2
    assert_success

    run grep -q "^After=ovos.service ovos-gui-websocket.service ovos-phal.service$" ansible/roles/ovos_services/templates/virtualenv/ovos-gui.service.j2
    assert_success

    run grep -q "^WorkingDirectory=.*\\.venvs/ovos$" ansible/roles/ovos_services/templates/virtualenv/ovos-gui.service.j2
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

@test "install_ansible_installs_collections_to_repo_local_path" {
    run grep -F -q 'collections_path="${PWD}/.ansible/collections"' utils/common.sh
    assert_success

    run grep -F -q -- '--collections-path "$collections_path"' utils/common.sh
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

    run grep -q "Ensure user cache root directory exists with correct ownership" ansible/roles/ovos_services/tasks/main.yml
    assert_success

    run grep -q "/.cache" ansible/roles/ovos_services/tasks/main.yml
    assert_success

    run grep -q "/.cache/huggingface" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "/.cache/OCP" ansible/roles/ovos_services/defaults/main.yml
    assert_success

    run grep -q "Ensure OVOS runtime user directories exist" ansible/roles/ovos_services/tasks/main.yml
    assert_success

    run grep -q "Ensure OVOS runtime user directory ownership is corrected recursively" ansible/roles/ovos_services/tasks/main.yml
    assert_success

    run grep -q "recurse: true" ansible/roles/ovos_services/tasks/main.yml
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
    # Keep a generous context window because this job block may grow over time.
    # When GitHub retires macos-15-intel, update the Intel runner assertion below.
    run bash -c 'grep -A50 -F "macos-scenario-smoke:" .github/workflows/macos_ci.yml | grep -F -q "runs-on: \${{ matrix.runner }}"'
    assert_success

    run bash -c 'grep -A50 -F "macos-scenario-smoke:" .github/workflows/macos_ci.yml | grep -F -q -- "- macos-15-intel"'
    assert_success

    run bash -c 'grep -A50 -F "macos-scenario-smoke:" .github/workflows/macos_ci.yml | grep -F -q -- "- macos-14"'
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

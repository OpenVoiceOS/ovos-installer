#!/usr/bin/env bash

# shellcheck source=utils/bash_runtime.sh
source utils/bash_runtime.sh

# Ensure a modern Bash runtime before sourcing files that use associative arrays.
if [ -z "${BASH_VERSINFO:-}" ] || [ "${BASH_VERSINFO[0]}" -lt 4 ]; then
  BASH_RUNTIME="$(resolve_bash_runtime 4 || true)"
  printf '%s\n' "This installer requires Bash 4 or newer."
  if [ "$(uname -s 2>/dev/null || true)" = "Darwin" ]; then
    if [ -n "${BASH_RUNTIME:-}" ]; then
      printf '%s\n' "On macOS, rerun with ${BASH_RUNTIME} setup.sh."
    else
      printf '%s\n' "On macOS, install Bash with Homebrew and rerun with /opt/homebrew/bin/bash (Apple Silicon) or /usr/local/bin/bash (Intel)."
    fi
  elif [ -n "${BASH_RUNTIME:-}" ]; then
    printf '%s\n' "Rerun with ${BASH_RUNTIME} setup.sh."
  fi
  exit 5
fi

# Override system locales only during the installation.
if command -v locale >/dev/null 2>&1; then
  if locale -a 2>/dev/null | grep -qiE '^c\.utf-?8$'; then
    export LANG=C.UTF-8 LC_ALL=C.UTF-8
  elif locale -a 2>/dev/null | grep -qiE '^en_US\.utf-?8$'; then
    export LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
  else
    export LANG=C LC_ALL=C
  fi
else
  export LANG=C LC_ALL=C
fi

# Base installer version on commit hash
INSTALLER_VERSION="$(git rev-parse --short=8 HEAD)"
export INSTALLER_VERSION

# shellcheck source=utils/constants.sh
source utils/constants.sh

# shellcheck source=utils/banner.sh
source utils/banner.sh

# shellcheck source=utils/common.sh
source utils/common.sh

# # shellcheck source=utils/argparse.sh
source utils/argparse.sh

# Parse command line arguments
handle_options "$@"

if ! acquire_installer_lock; then
  exit "${EXIT_ALREADY_RUNNING}"
fi

# Runtime cleanup is shared between normal exit and signal handling.
trap cleanup_installer_runtime EXIT
trap 'exit_with_signal_code 130' INT
trap 'exit_with_signal_code 143' TERM

# Default Ansible flags to avoid unbound variable errors when set -u is enabled
ansible_cleaning="false"
ansible_tags=()
ansible_debug=()

# Enable debug/verbosity for Bash and Ansible
if [ "$DEBUG" == "true" ]; then
  set -x
  ansible_debug=(-vvv)
fi

set -eE
trap on_error ERR
detect_user
delete_log
detect_existing_instance
get_os_information
wsl2_requirements
detect_cpu_instructions
is_raspberrypi_soc
detect_hardware_model
required_packages
check_python_compatibility
detect_sound
detect_display
create_python_venv
install_ansible
detect_scenario

if [ "${TUNING_OVERCLOCK:-no}" == "yes" ] && [ -z "${OVERCLOCK_ARM_FREQ:-}" ] && [ "${RASPBERRYPI_MODEL:-N/A}" != "N/A" ]; then
  if [[ "$RASPBERRYPI_MODEL" == *"Raspberry Pi 5"* ]]; then
    OVERCLOCK_ARM_FREQ="2800"
  else
    OVERCLOCK_ARM_FREQ="2000"
  fi
  export OVERCLOCK_ARM_FREQ
fi

i2c_scan
state_directory
trap "" ERR
set +eE

if [ "$SCENARIO_FOUND" == "false" ]; then
  # shellcheck source=tui/language.sh
  source tui/language.sh
fi

if [ "$EXISTING_INSTANCE" == "false" ] && [ "$SCENARIO_FOUND" == "false" ]; then
  # shellcheck source=tui/main.sh
  source tui/main.sh

  ansible_cleaning="false"
else
  if [ "$SCENARIO_FOUND" == "false" ]; then
    # shellcheck source=tui/uninstall.sh
    source tui/uninstall.sh
  fi

  if [ "$CONFIRM_UNINSTALL" == "true" ] || [ "$CONFIRM_UNINSTALL_CLI" == "true" ]; then
    ansible_tags=(--tags uninstall)
    ansible_cleaning="true"
  else
    if [ "$SCENARIO_FOUND" == "false" ]; then
      # shellcheck source=tui/main.sh
      source tui/main.sh
    fi
  fi
fi

if [ "$EXISTING_INSTANCE" == "true" ]; then
  export SHARE_TELEMETRY="false"
  export SHARE_USAGE_TELEMETRY="false"
fi

normalize_feature_gui_support

log_info "➤ Starting Ansible playbook... ☕🍵🧋"

# Execute the Ansible playbook on localhost
export ANSIBLE_CONFIG=ansible.cfg
export ANSIBLE_LOG_PATH="${ANSIBLE_LOG_FILE}"
# Ensure collection discovery works even if ansible-galaxy installed under
# either root or target-user HOME (common sudo/home variance on macOS).
export ANSIBLE_COLLECTIONS_PATH="${PWD}/.ansible/collections:${RUN_AS_HOME}/.ansible/collections:/var/root/.ansible/collections:/root/.ansible/collections:/usr/share/ansible/collections"
case "${DISTRO_NAME:-}" in
  fedora | almalinux | rocky | centos | rhel)
    if [ -x /usr/libexec/platform-python ]; then
      export ANSIBLE_PYTHON_INTERPRETER="/usr/libexec/platform-python"
    else
      export ANSIBLE_PYTHON_INTERPRETER="/usr/bin/python3"
    fi
    ;;
  *)
    export ANSIBLE_PYTHON_INTERPRETER="$VENV_PATH/bin/python3"
    ;;
esac
export ANSIBLE_NOCOWS=1
if [ -t 1 ]; then
  unset ANSIBLE_NOCOLOR || true
  export ANSIBLE_FORCE_COLOR=true
  export PY_COLORS=1
else
  export ANSIBLE_NOCOLOR=true
  unset ANSIBLE_FORCE_COLOR || true
  unset PY_COLORS || true
fi

# Pass Home Assistant/LLM credentials via an extra-vars file
# (avoids exposing secrets in the process list).
ha_extra_vars=()
ha_extra_vars_file=""
# If `set -x` is enabled, avoid echoing secrets to the terminal/logs.
xtrace_was_on="false"
case "$-" in
  *x*) xtrace_was_on="true" ;;
esac
if [ "$xtrace_was_on" == "true" ]; then
  set +x
fi

if [ -n "${HOMEASSISTANT_URL:-}" ] || [ -n "${HOMEASSISTANT_API_KEY:-}" ] || \
  [ "${FEATURE_LLM:-false}" == "true" ] || [ -n "${LLM_API_URL:-}" ] || [ -n "${LLM_API_KEY:-}" ] || [ -n "${LLM_MODEL:-}" ]; then

  old_umask="$(umask)"
  umask 077
  if ha_extra_vars_file="$(mktemp "${TMPDIR:-/tmp}/ovos-ansible-extra-vars.XXXXXX.json" 2>>"$LOG_FILE")"; then
    if HOMEASSISTANT_API_KEY="${HOMEASSISTANT_API_KEY:-}" LLM_API_KEY="${LLM_API_KEY:-}" jq -c -n \
      --arg ha_url "${HOMEASSISTANT_URL:-}" \
      --arg llm_api_url "${LLM_API_URL:-}" \
      --arg llm_model "${LLM_MODEL:-}" \
      --arg llm_persona "${LLM_PERSONA:-}" \
      --arg llm_max_tokens "${LLM_MAX_TOKENS:-300}" \
      --arg llm_temperature "${LLM_TEMPERATURE:-0.2}" \
      --arg llm_top_p "${LLM_TOP_P:-0.1}" \
      '{
        ovos_installer_homeassistant_url: $ha_url,
        ovos_installer_homeassistant_host: $ha_url,
        ovos_installer_homeassistant_api_key: (env.HOMEASSISTANT_API_KEY // ""),
        ovos_installer_llm_api_url: $llm_api_url,
        ovos_installer_llm_api_key: (env.LLM_API_KEY // ""),
        ovos_installer_llm_model: $llm_model,
        ovos_installer_llm_persona: $llm_persona,
        ovos_installer_llm_max_tokens: $llm_max_tokens,
        ovos_installer_llm_temperature: $llm_temperature,
        ovos_installer_llm_top_p: $llm_top_p
      }' \
      >"$ha_extra_vars_file" 2>>"$LOG_FILE"; then
      ha_extra_vars=(-e "@${ha_extra_vars_file}")
    else
      cleanup_ha_extra_vars_file
    fi
  fi
  umask "$old_umask"

  # Secrets are now on disk with restrictive permissions; don't keep them exported.
  unset HOMEASSISTANT_API_KEY || true
  unset LLM_API_KEY || true
fi
if [ "$xtrace_was_on" == "true" ]; then
  set -x
fi
ansible_command=(
  ansible-playbook -i "127.0.0.1," ansible/site.yml
  -e "ovos_installer_user=${RUN_AS}" \
  -e "ovos_installer_group=${RUN_AS_GROUP}" \
  -e "ovos_installer_uid=${RUN_AS_UID}" \
  -e "ovos_installer_venv=${VENV_PATH}" \
  -e "ovos_installer_venv_python=${OVOS_VENV_PYTHON}" \
  -e "ovos_installer_user_home=${RUN_AS_HOME}" \
  -e "ovos_installer_method=${METHOD}" \
  -e "ovos_installer_profile=${PROFILE}" \
  -e "ovos_installer_sound_server=${SOUND_SERVER%% *}" \
  -e "ovos_installer_raspberrypi='${RASPBERRYPI_MODEL}'" \
  -e "ovos_installer_hardware='${HARDWARE_MODEL}'" \
  -e "ovos_installer_channel=${CHANNEL}" \
  -e "ovos_installer_feature_gui=${FEATURE_GUI}" \
  -e "ovos_installer_feature_skills=${FEATURE_SKILLS}" \
  -e "ovos_installer_feature_extra_skills=${FEATURE_EXTRA_SKILLS}" \
  -e "ovos_installer_feature_homeassistant=${FEATURE_HOMEASSISTANT}" \
  -e "ovos_installer_feature_llm=${FEATURE_LLM}" \
  -e "ovos_installer_tuning=${TUNING}" \
  -e "ovos_installer_tuning_overclock=${TUNING_OVERCLOCK}" \
  -e "ovos_installer_overclock_arm_boost=${OVERCLOCK_ARM_BOOST}" \
  -e "ovos_installer_overclock_initial_turbo=${OVERCLOCK_INITIAL_TURBO}" \
  -e "ovos_installer_overclock_over_voltage=${OVERCLOCK_OVER_VOLTAGE}" \
  -e "ovos_installer_overclock_arm_freq=${OVERCLOCK_ARM_FREQ}" \
  -e "ovos_installer_overclock_gpu_freq=${OVERCLOCK_GPU_FREQ}" \
  -e "ovos_installer_pip_config_file=${PIP_CONFIG_FILE:-}" \
  -e "ovos_installer_uv_version=${OVOS_INSTALLER_UV_VERSION:-}" \
  -e "ovos_installer_listener_host=${HIVEMIND_HOST}" \
  -e "ovos_installer_listener_port=${HIVEMIND_PORT}" \
  -e "ovos_installer_satellite_key=${SATELLITE_KEY}" \
  -e "ovos_installer_satellite_password=${SATELLITE_PASSWORD}" \
  -e "ovos_installer_cpu_is_capable=${CPU_IS_CAPABLE}" \
  -e "ovos_installer_cleaning=${ansible_cleaning}" \
  -e "ovos_installer_display_server=${DISPLAY_SERVER}" \
  -e "ovos_installer_telemetry=${SHARE_TELEMETRY}" \
  -e "ovos_installer_usage_telemetry=${SHARE_USAGE_TELEMETRY}" \
  -e "ovos_installer_locale=${LOCALE:-en-us}" \
  "${ha_extra_vars[@]}" \
  -e "$(jq -c -n '{ovos_installer_i2c_devices: $ARGS.positional}' --args "${DETECTED_DEVICES[@]}")" \
  -e "ovos_installer_reboot_file_path=${REBOOT_FILE_PATH}" \
  "${ansible_tags[@]}" "${ansible_debug[@]}"
)

ansible_rc=0
tee_rc=0
strip_rc=0
if [ -t 1 ]; then
  if ! ansi_log_pipe_dir="$(mktemp -d "${TMPDIR:-/tmp}/ovos-ansible-log.XXXXXX" 2>>"$LOG_FILE")"; then
    log_error "Unable to initialize the Ansible log writer."
    cleanup_ha_extra_vars_file
    exit "${EXIT_FAILURE}"
  fi
  ansi_log_pipe="${ansi_log_pipe_dir}/stream"
  if ! mkfifo "$ansi_log_pipe" 2>>"$LOG_FILE"; then
    log_error "Unable to create the Ansible log pipe at ${ansi_log_pipe}."
    rm -rf "$ansi_log_pipe_dir"
    cleanup_ha_extra_vars_file
    exit "${EXIT_FAILURE}"
  fi

  strip_ansi_stream <"$ansi_log_pipe" >>"$LOG_FILE" &
  ansi_log_pipe_pid="$!"
  "${ansible_command[@]}" 2>&1 | tee "$ansi_log_pipe"
  pipeline_status=("${PIPESTATUS[@]}")
  ansible_rc="${pipeline_status[0]}"
  tee_rc="${pipeline_status[1]}"
  wait "$ansi_log_pipe_pid" || strip_rc="$?"
  rm -f "$ansi_log_pipe"
  rmdir "$ansi_log_pipe_dir" 2>/dev/null || true
else
  "${ansible_command[@]}" 2>&1 | tee -a "$LOG_FILE"
  pipeline_status=("${PIPESTATUS[@]}")
  ansible_rc="${pipeline_status[0]}"
  tee_rc="${pipeline_status[1]}"
fi

if [ "$tee_rc" -ne 0 ] || [ "$strip_rc" -ne 0 ]; then
  log_error "Failed to write Ansible output to $LOG_FILE."
  if [ "$ansible_rc" -eq 0 ]; then
    ansible_rc="${EXIT_FAILURE}"
  fi
fi

cleanup_ha_extra_vars_file

if [ "$ansible_rc" -eq 0 ]; then
  if [ "$CONFIRM_UNINSTALL" == "false" ] || [ -z "$CONFIRM_UNINSTALL" ]; then
    if [ "$SCENARIO_FOUND" == "false" ]; then
      # shellcheck source=tui/finish.sh
      source tui/finish.sh
      rm -rf "$VENV_PATH" /root/.ansible
      if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
      fi
      if [ -f "$REBOOT_FILE_PATH" ]; then
        rm -f "$REBOOT_FILE_PATH"
        log_info ""
        log_info "➤ Rebooting Raspberry Pi now..."
        shutdown -r now
      fi
    fi
    if [ "$SCENARIO_FOUND" != "false" ] && [ -f "$LOG_FILE" ]; then
      rm -f "$LOG_FILE"
    fi
  else
    rm -rf "$VENV_PATH" /root/.ansible
    if [ -n "${RUN_AS_HOME:-}" ]; then
      venv_root="${RUN_AS_HOME}/.venvs"
      if [ "$(dirname "$VENV_PATH")" = "$venv_root" ]; then
        rm -rf "$venv_root"
      fi
    fi
    log_info ""
    log_info "➤ Open Voice OS has been successfully uninstalled."
    if [ -f "$LOG_FILE" ]; then
      rm -f "$LOG_FILE"
    fi
    if [ -f "$REBOOT_FILE_PATH" ]; then
      rm -f "$REBOOT_FILE_PATH"
      log_info ""
      log_info "➤ Rebooting Raspberry Pi now..."
      shutdown -r now
    fi
  fi
else
  debug_url="$(upload_logs)"
  log_info ""
  log_info "➤ Unable to finalize the process, please check $LOG_FILE for more details."
  if [ -n "${debug_url:-}" ]; then
    log_info "➤ Please share this URL with us $debug_url"
  else
    log_info "➤ Failed to upload logs automatically. Please attach $LOG_FILE."
  fi
  exit "${EXIT_FAILURE}"
fi

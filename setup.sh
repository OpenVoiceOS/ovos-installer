#!/usr/bin/env bash
# Override system's locales only during the installation
export LANG=C.UTF-8 LC_ALL=C.UTF-8

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
check_python_compatibility
wsl2_requirements
detect_cpu_instructions
is_raspeberrypi_soc
detect_sound
detect_display
required_packages
create_python_venv
install_ansible
download_yq
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

echo "➤ Starting Ansible playbook... ☕🍵🧋"

# Execute the Ansible playbook on localhost
export ANSIBLE_CONFIG=ansible.cfg
export ANSIBLE_LOG_PATH="${ANSIBLE_LOG_FILE}"
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
  # ansible-playbook output is piped through tee, so force colors for interactive sessions.
  export ANSIBLE_FORCE_COLOR=true
  export PY_COLORS=1
fi

# Pass Home Assistant token via an extra-vars file (avoids exposing secrets in the process list).
ha_extra_vars=()
ha_extra_vars_file=""
cleanup_ha_extra_vars_file() {
  if [ -n "${ha_extra_vars_file:-}" ]; then
    rm -f "$ha_extra_vars_file" 2>/dev/null || true
    ha_extra_vars_file=""
  fi
}
trap cleanup_ha_extra_vars_file EXIT INT TERM
if [ -n "${HOMEASSISTANT_URL:-}" ] || [ -n "${HOMEASSISTANT_API_KEY:-}" ]; then
  # If `set -x` is enabled, avoid echoing secrets to the terminal/logs.
  xtrace_was_on="false"
  case "$-" in
    *x*) xtrace_was_on="true" ;;
  esac
  if [ "$xtrace_was_on" == "true" ]; then
    set +x
  fi

  old_umask="$(umask)"
  umask 077
  if ha_extra_vars_file="$(mktemp "${TMPDIR:-/tmp}/ovos-ansible-extra-vars.XXXXXX.json" 2>>"$LOG_FILE")"; then
    # Use env.HOMEASSISTANT_API_KEY so the token does not appear in the process args.
    if HOMEASSISTANT_API_KEY="${HOMEASSISTANT_API_KEY:-}" jq -c -n --arg url "${HOMEASSISTANT_URL:-}" \
      '{ovos_installer_homeassistant_url: $url, ovos_installer_homeassistant_host: $url, ovos_installer_homeassistant_api_key: (env.HOMEASSISTANT_API_KEY // "")}' \
      >"$ha_extra_vars_file" 2>>"$LOG_FILE"; then
      ha_extra_vars=(-e "@${ha_extra_vars_file}")
    else
      cleanup_ha_extra_vars_file
    fi
  fi
  umask "$old_umask"

  # The token is now on disk with restrictive permissions; don't keep it exported.
  unset HOMEASSISTANT_API_KEY || true

  if [ "$xtrace_was_on" == "true" ]; then
    set -x
  fi
fi
ansible-playbook -i 127.0.0.1, ansible/site.yml \
  -e "ovos_installer_user=${RUN_AS}" \
  -e "ovos_installer_group=$(id -ng "$RUN_AS")" \
  -e "ovos_installer_uid=${RUN_AS_UID}" \
  -e "ovos_installer_venv=${VENV_PATH}" \
  -e "ovos_installer_venv_python=${OVOS_VENV_PYTHON}" \
  -e "ovos_installer_user_home=${RUN_AS_HOME}" \
  -e "ovos_installer_method=${METHOD}" \
  -e "ovos_installer_profile=${PROFILE}" \
  -e "ovos_installer_sound_server=$(echo "$SOUND_SERVER" | awk '{ print $1 }')" \
  -e "ovos_installer_raspberrypi='${RASPBERRYPI_MODEL}'" \
  -e "ovos_installer_channel=${CHANNEL}" \
  -e "ovos_installer_feature_gui=${FEATURE_GUI}" \
  -e "ovos_installer_feature_skills=${FEATURE_SKILLS}" \
  -e "ovos_installer_feature_extra_skills=${FEATURE_EXTRA_SKILLS}" \
  -e "ovos_installer_feature_homeassistant=${FEATURE_HOMEASSISTANT}" \
  -e "ovos_installer_tuning=${TUNING}" \
  -e "ovos_installer_tuning_overclock=${TUNING_OVERCLOCK}" \
  -e "ovos_installer_overclock_arm_boost=${OVERCLOCK_ARM_BOOST}" \
  -e "ovos_installer_overclock_initial_turbo=${OVERCLOCK_INITIAL_TURBO}" \
  -e "ovos_installer_overclock_over_voltage=${OVERCLOCK_OVER_VOLTAGE}" \
  -e "ovos_installer_overclock_arm_freq=${OVERCLOCK_ARM_FREQ}" \
  -e "ovos_installer_overclock_gpu_freq=${OVERCLOCK_GPU_FREQ}" \
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
  "${ansible_tags[@]}" "${ansible_debug[@]}" 2>&1 | tee -a "$LOG_FILE"

# Retrieve the ansible-playbook status code from the pipeline and check for success or failure
ansible_rc="${PIPESTATUS[0]}"
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
        printf '\n%s\n' "➤ Rebooting Raspberry Pi now..."
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
    printf '\n%s\n' "➤ Open Voice OS has been successfully uninstalled."
    if [ -f "$LOG_FILE" ]; then
      rm -f "$LOG_FILE"
    fi
    if [ -f "$REBOOT_FILE_PATH" ]; then
      rm -f "$REBOOT_FILE_PATH"
      printf '\n%s\n' "➤ Rebooting Raspberry Pi now..."
      shutdown -r now
    fi
  fi
else
  debug_url="$(upload_logs)"
  printf '\n%s\n' "➤ Unable to finalize the process, please check $LOG_FILE for more details."
  if [ -n "${debug_url:-}" ]; then
    printf '%s\n' "➤ Please share this URL with us $debug_url"
  else
    printf '%s\n' "➤ Failed to upload logs automatically. Please attach $LOG_FILE."
  fi
  exit "${EXIT_FAILURE}"
fi

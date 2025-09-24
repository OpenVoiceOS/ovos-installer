#!/bin/env bash

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
is_raspeberrypi_soc
detect_sound
detect_display
required_packages
create_python_venv
install_ansible
download_yq
detect_scenario
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
export ANSIBLE_CONFIG=ansible/ansible.cfg
export ANSIBLE_PYTHON_INTERPRETER="$VENV_PATH/bin/python3"
export ANSIBLE_NOCOWS=1
ansible-playbook -i 127.0.0.1, ansible/site.yml \
  -e "ovos_installer_user=${RUN_AS}" \
  -e "ovos_installer_group=$(id -ng "$RUN_AS")" \
  -e "ovos_installer_uid=${RUN_AS_UID}" \
  -e "ovos_installer_venv=${VENV_PATH}" \
  -e "ovos_installer_user_home=${RUN_AS_HOME}" \
  -e "ovos_installer_method=${METHOD}" \
  -e "ovos_installer_profile=${PROFILE}" \
  -e "ovos_installer_sound_server=$(echo "$SOUND_SERVER" | awk '{ print $1 }')" \
  -e "ovos_installer_raspberrypi='${RASPBERRYPI_MODEL}'" \
  -e "ovos_installer_channel=${CHANNEL}" \
  -e "ovos_installer_feature_gui=${FEATURE_GUI}" \
  -e "ovos_installer_feature_skills=${FEATURE_SKILLS}" \
  -e "ovos_installer_feature_extra_skills=${FEATURE_EXTRA_SKILLS}" \
  -e "ovos_installer_tuning=${TUNING}" \
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
  -e "ovos_installer_i2c_devices=$(jq -c -n '$ARGS.positional' --args "${DETECTED_DEVICES[@]}")" \
  -e "ovos_installer_reboot_file_path=${REBOOT_FILE_PATH}" \
  "${ansible_tags[@]}" "${ansible_debug[@]}"

# Retrieve the ansible-playbook status code before tee command and check for success or failure
if [ "${PIPESTATUS[0]}" -eq 0 ]; then
  if [ "$CONFIRM_UNINSTALL" == "false" ] || [ -z "$CONFIRM_UNINSTALL" ]; then
    if [ "$SCENARIO_FOUND" == "false" ]; then
      # shellcheck source=tui/finish.sh
      source tui/finish.sh
      rm -rf "$VENV_PATH" /root/.ansible
      if [ -f "$REBOOT_FILE_PATH" ]; then
        rm -f "$REBOOT_FILE_PATH"
        shutdown -r now
      fi
    fi
  else
    rm -rf "$VENV_PATH" /root/.ansible
    printf '\n%s\n' "➤ Open Voice OS has been successfully uninstalled."
  fi
else
  # Concatenate Ansible log with installer log
  cat "$ANSIBLE_LOG_FILE" >>"$LOG_FILE"
  debug_url="$(curl -sF 'content=<-' "${PASTE_URL}/api/" <"$LOG_FILE")"
  printf '\n%s\n' "➤ Unable to finalize the process, please check $LOG_FILE for more details."
  printf '%s\n' "➤ Please share this URL with us $debug_url"
  exit "${EXIT_FAILURE}"
fi

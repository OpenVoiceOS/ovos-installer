#!/bin/env bash

source utils/constants.sh
source utils/banner.sh
source utils/common.sh

detect_user
detect_existing_instance
get_distro
detect_cpu_instructions
is_raspeberrypi_soc
detect_sound
detect_x
delete_log
required_packages
create_python_venv
install_ansible

if [[ "$EXISTING_INSTANCE" == "false" ]]; then
  source tui/main.sh
  ansible_cleaning="false"
else
  source tui/language.sh
  source "tui/locales/$LOCALE/misc.sh"
  source tui/uninstall.sh
  if [[ "$CONFIRM_UNINSTALL" == "true" ]]; then
    ansible_tags="--tags uninstall"
    ansible_cleaning="true"
  else
    source tui/main.sh
  fi
fi

echo "➤ Starting Ansible playbook... ☕🍵🧋"

export ANSIBLE_CONFIG=ansible/ansible.cfg
export ANSIBLE_PYTHON_INTERPRETER="$VENV_PATH/bin/python3"
unbuffer ansible-playbook -i 127.0.0.1, ansible/site.yml \
    -e "ovos_installer_user=${RUN_AS}" \
    -e "ovos_installer_uid=${RUN_AS_UID}" \
    -e "ovos_installer_venv=${VENV_PATH}" \
    -e "ovos_installer_user_home=${RUN_AS_HOME}" \
    -e "ovos_installer_method=${METHOD}" \
    -e "ovos_installer_profile=${PROFILE}" \
    -e "ovos_installer_sound_server=$(echo "$SOUND_SERVER" | awk '{ print $1 }')" \
    -e "ovos_installer_raspberrypi=${RASPBERRYPI_MODEL}" \
    -e "ovos_installer_channel=${CHANNEL}" \
    -e "ovos_installer_feature_gui=${FEATURE_GUI}" \
    -e "ovos_installer_feature_skills=${FEATURE_SKILLS}" \
    -e "ovos_installer_tuning=${TUNING}" \
    -e "ovos_installer_listener_host=${HIVEMIND_HOST}" \
    -e "ovos_installer_listener_port=${HIVEMIND_PORT}" \
    -e "ovos_installer_satellite_key=${SATELLITE_KEY}" \
    -e "ovos_installer_satellite_password=${SATELLITE_PASSWORD}" \
    -e "ovos_installer_cpu_is_capable=${CPU_IS_CAPABLE}" \
    -e "ovos_installer_cleaning=${ansible_cleaning}" \
    $ansible_tags "$@" | tee -a "$LOG_FILE"

if [ "${PIPESTATUS[0]}" == 0 ]; then
  if [[ "$CONFIRM_UNINSTALL" == "false" ]] || [[ -z "$CONFIRM_UNINSTALL" ]]; then
    source tui/finish.sh
  else
    echo ""
    echo "➤ Open Voice OS has been successfully uninstalled."
  fi
else
    echo ""
    echo "➤ Unable to finalize the process, please check $LOG_FILE for more details."
fi

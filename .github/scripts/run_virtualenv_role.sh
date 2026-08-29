#!/usr/bin/env bash
# Run the ovos_virtualenv role on its own, without setup.sh.
#
# Distributions that are not available as GitHub runners have to be covered
# from a container, and a container has no init system for the launchd/systemd
# work that a full setup.sh run performs. Driving the role directly still
# exercises the package, virtualenv and build-shim tasks, which is where
# distribution differences (compilers, swig, fann) actually show up.
set -euo pipefail

cleaning="${1:-false}"

install_user="${OVOS_CI_INSTALL_USER:?OVOS_CI_INSTALL_USER is required}"
install_home="${OVOS_CI_INSTALL_HOME:?OVOS_CI_INSTALL_HOME is required}"
ansible_playbook="${OVOS_CI_ANSIBLE_PLAYBOOK:-/opt/ansible-venv/bin/ansible-playbook}"

if [ ! -x "$ansible_playbook" ]; then
    printf '%s\n' "ansible-playbook not found at ${ansible_playbook}" >&2
    exit 1
fi

ANSIBLE_CONFIG="${PWD}/ansible.cfg" \
    ANSIBLE_CALLBACKS_ENABLED="profile_tasks,timer" \
    "$ansible_playbook" -i 127.0.0.1, ansible/site.yml \
    -e "ovos_installer_user=${install_user}" \
    -e "ovos_installer_group=${install_user}" \
    -e "ovos_installer_uid=$(id -u "${install_user}")" \
    -e "ovos_installer_user_home=${install_home}" \
    -e "ovos_installer_method=virtualenv" \
    -e "ovos_installer_profile=ovos" \
    -e "ovos_installer_channel=testing" \
    -e "ovos_installer_feature_gui=false" \
    -e "ovos_installer_feature_skills=false" \
    -e "ovos_installer_feature_extra_skills=false" \
    -e "ovos_installer_feature_homeassistant=false" \
    -e "ovos_installer_tuning=false" \
    -e "ovos_installer_cleaning=${cleaning}" \
    -e "ovos_installer_raspberrypi=N/A" \
    -e "ovos_installer_hardware=N/A" \
    -e "ovos_installer_sound_server=N/A" \
    -e "ovos_installer_display_server=N/A" \
    -e "ovos_installer_locale=en-us" \
    -e "ovos_installer_reboot_file_path=/tmp/ovos.reboot" \
    -e "ovos_installer_venv=${install_home}/.venvs/ovos" \
    -e "ovos_installer_venv_python=3.11" \
    -e '{"ovos_installer_i2c_devices":[]}' \
    --tags ovos_virtualenv

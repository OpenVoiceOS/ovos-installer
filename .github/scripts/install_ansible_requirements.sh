#!/usr/bin/env bash
set -euo pipefail

with_grapher="false"
force_collections="false"

while [ "$#" -gt 0 ]; do
    case "$1" in
    --with-grapher)
        with_grapher="true"
        ;;
    --force-collections)
        force_collections="true"
        ;;
    *)
        printf '%s\n' "Unknown option: $1" >&2
        exit 2
        ;;
    esac
    shift
done

if [ "${OVOS_CI_CLEAR_ANSIBLE_CACHE:-true}" = "true" ]; then
    rm -rf "${HOME}/.ansible"
fi

python -m pip install --upgrade pip

pip_packages=("ansible" "ansible-lint")
if [ "$with_grapher" = "true" ]; then
    pip_packages=("ansible-playbook-grapher" "${pip_packages[@]}")
fi

python -m pip install "${pip_packages[@]}"

if [ "$with_grapher" = "true" ] && command -v apt-get >/dev/null 2>&1; then
    sudo apt-get --no-install-recommends install -y graphviz
fi

collection_args=()
if [ "$force_collections" = "true" ]; then
    collection_args+=("--force")
fi

galaxy_install_ok="false"
for galaxy_server in \
    "https://galaxy.ansible.com" \
    "https://galaxy.ansible.com/api/" \
    "https://galaxy.ansible.com/api/v3/" \
    "https://galaxy.ansible.com/api/v2/"; do
    for attempt in 1 2 3; do
        if ansible-galaxy collection install -r ansible/requirements.yml "${collection_args[@]}" --server "$galaxy_server"; then
            galaxy_install_ok="true"
            break 2
        fi
        sleep $((attempt * 5))
    done
done

if [ "$galaxy_install_ok" != "true" ]; then
    printf '%s\n' "ansible-galaxy collection install failed after retries on all known endpoints" >&2
    exit 1
fi

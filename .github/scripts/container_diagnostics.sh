#!/usr/bin/env bash
# After a failed job: what each container went through, what the messagebus and core
# said last, and whether the kernel killed anything for memory. The round trip once lost
# its bus connection on a containers job and nothing in the dump said why.
set -uo pipefail

command -v docker >/dev/null 2>&1 || exit 0

docker_cli() {
    if docker info >/dev/null 2>&1; then
        docker "$@"
    else
        sudo -n docker "$@"
    fi
}

echo "== containers"
docker_cli ps -a --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'

ids="$(docker_cli ps -aq)"
if [ -n "$ids" ]; then
    echo "== restarts, OOM kills and exit codes"
    # shellcheck disable=SC2086 # one argument per container id
    docker_cli inspect --format \
        '{{.Name}} restarts={{.RestartCount}} oom_killed={{.State.OOMKilled}} exit={{.State.ExitCode}} {{.State.Error}}' $ids

    for name in ovos_messagebus ovos_core; do
        if docker_cli inspect "$name" >/dev/null 2>&1; then
            echo "== the last of ${name}"
            docker_cli logs --tail 150 "$name" 2>&1
        fi
    done
fi

echo "== the kernel on memory"
sudo -n dmesg 2>/dev/null | grep -i -E 'out of memory|oom-kill|killed process' | tail -n 20

exit 0

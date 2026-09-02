#!/usr/bin/env bash
# Decide whether a platform's jobs need to run for the changes in a pull
# request.
#
# The rule is deliberately one-sided: run unless every changed file is
# provably specific to another platform. Skipping a job that was needed is
# far worse than running one that was not, so anything shared, anything
# unrecognised, and anything outside a pull request all mean "run".
set -euo pipefail

platform="${1:?usage: platform_changes.sh <macos|linux> [base_sha]}"
base_sha="${2:-}"

# Files that cannot change what an install does on any platform, so a change
# touching only these needs no install run at all. Kept deliberately narrow:
# prose, pictures and repository furniture. Not scripts/, not tests/, not
# workflows - those can all change behaviour or the run itself.
docs_only='^README\.md$
^LICENSE$
^docs/
^\.github/CODEOWNERS$
^\.github/CODE_OF_CONDUCT\.md$
^\.github/ISSUE_TEMPLATE/
^\.jekyllignore$
^\.nojekyll$
^\.well-known/'

# Files that only affect a Linux install, so macOS jobs can ignore them.
# Containers are Linux only here: the macOS matrix installs virtualenv.
linux_only='^ansible/roles/ovos_containers/
^ansible/roles/ovos_hardware_mark[12]/
^ansible/roles/ovos_(network|performance|storage|audio)_tuning/
^ansible/roles/ovos_services/tasks/systemd
^ansible/roles/ovos_services/templates/virtualenv/
^ansible/roles/ovos_installer/tasks/package_tracking_prepare_linux\.yml$
^tests/bats/(i2c|raspberrypi)\.bats$
^\.github/workflows/scenarios-'

# Files that only affect a macOS install, so Linux jobs can ignore them.
macos_only='^ansible/roles/ovos_services/tasks/launchd\.yml$
^ansible/roles/ovos_services/tasks/uninstall-launchd\.yml$
^ansible/roles/ovos_services/templates/launchd/
^ansible/roles/ovos_installer/tasks/package_tracking_prepare_macos\.yml$
^tests/bats/macos_support\.bats$
^\.github/workflows/macos_ci\.yml$'

case "$platform" in
    macos) other_platform_only="$linux_only" ;;
    linux) other_platform_only="$macos_only" ;;
    *) printf 'unknown platform: %s\n' "$platform" >&2; exit 2 ;;
esac

# No base to compare against, so there is nothing to reason about.
if [ -z "$base_sha" ]; then
    printf 'run=true\n'
    exit 0
fi

changed="$(git diff --name-only "${base_sha}...HEAD")"

if [ -z "$changed" ]; then
    printf 'run=true\n'
    exit 0
fi

# A documentation-only change cannot break an install, and running the full
# matrix for a typo costs an hour of runners for no information.
if ! grep -qvE "$(printf '%s' "$docs_only" | paste -sd'|' -)" <<<"$changed"; then
    printf 'run=false\n'
    exit 0
fi

# Run as soon as one changed file is not exclusive to the other platform.
#
# The list is fed in as a here-string rather than through a pipe. grep -q
# stops at its first match, which leaves the writer of a pipe holding a
# closed pipe, and under pipefail that SIGPIPE becomes the status of the
# whole pipeline. On a large enough change set that turned "a shared file
# was touched" into run=false, which is the one answer this must never give
# by accident.
if grep -qvE "$(printf '%s' "$other_platform_only" | paste -sd'|' -)" <<<"$changed"; then
    printf 'run=true\n'
else
    printf 'run=false\n'
fi

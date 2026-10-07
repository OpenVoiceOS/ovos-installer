#!/usr/bin/env bash
# What a package manager considers unneeded: installed as a dependency of something,
# and required by nothing installed now. One name per line, sorted.
#
#   unneeded_packages.sh list <family>
#   unneeded_packages.sh remove <family>
#
# remove takes out what is unneeded now and was not before the install, by name and
# nothing else, so what the machine already had no use for stays. The names unneeded
# before come one per line in OVOS_UNNEEDED_BEFORE. It goes a layer at a time: what it
# removes can leave its own dependencies needed by nothing in turn.
#
# <family> is Ansible's os_family: RedHat (dnf), Suse (zypper) or Archlinux (pacman).
set -uo pipefail
export LC_ALL=C

list() {
    case "$1" in
    RedHat) dnf repoquery --unneeded --queryformat '%{name}\n' ;;
    Suse)
        zypper --quiet --non-interactive packages --unneeded |
            awk -F'|' '$1 ~ /^i/ { gsub(/ /, "", $3); print $3 }'
        ;;
    # pacman -Qtdq exits 1 when nothing is unneeded, which is not a failure.
    Archlinux) pacman -Qtdq || [ "$?" -eq 1 ] ;;
    *)
        echo "no list of unneeded packages for '$1'" >&2
        return 2
        ;;
    esac | sed '/^[[:space:]]*$/d' | sort -u
}

remove_by_name() {
    local family="$1"
    shift
    case "$family" in
    RedHat) rpm -e "$@" ;;
    Suse) zypper --non-interactive remove --no-clean-deps "$@" ;;
    Archlinux) pacman -R --noconfirm "$@" ;;
    esac
}

case "${1:-}" in
list)
    list "${2:-}"
    ;;
remove)
    family="${2:-}"
    before="$(printf '%s\n' "${OVOS_UNNEEDED_BEFORE:-}" | sed '/^[[:space:]]*$/d' | sort -u)"
    for _ in 1 2 3 4 5 6 7 8; do
        now="$(list "$family")" || exit 1
        mapfile -t left < <(comm -23 <(printf '%s\n' "$now" | sed '/^$/d') <(printf '%s\n' "$before" | sed '/^$/d'))
        [ "${#left[@]}" -gt 0 ] || exit 0
        echo "removing: ${left[*]}"
        remove_by_name "$family" "${left[@]}" || exit 1
    done
    ;;
*)
    echo "usage: $0 list|remove <family>" >&2
    exit 2
    ;;
esac

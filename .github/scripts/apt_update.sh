#!/usr/bin/env bash
# apt-get update, without the third-party repositories nothing here installs from.
#
# The GitHub runner image ships apt sources for Google Chrome and Microsoft. Neither
# provides a package this repository installs - every job wants bash, jq, expect,
# whiptail, git, curl and bats, all from the Ubuntu archive - but a broken index on
# either one fails apt-get update, and the job dies at setup with exit code 100 before
# a single test runs.
#
# That is not hypothetical: on 2026-09-09 dl.google.com served a Packages.gz whose hash
# did not match its own Release file, and every amd64 Linux job here failed for hours.
# Retrying does not help while the upstream index stays inconsistent.
#
# Matched by content rather than by file name: the image has used both google-chrome.list
# and the deb822 google-chrome.sources, so deleting a fixed name silently does nothing -
# which is exactly how the first attempt at this fix passed on arm64, where the repository
# is absent, and kept failing on amd64.
#
# A mirror can also stop answering in the middle of a transfer, and apt-get update then
# waits until the job's own time limit: on 2026-10-07 three amd64 jobs that started within
# six minutes of each other sat over 40 minutes on it. Each attempt is bounded, and one
# that stalls or fails is tried again.
set -euo pipefail

sources_dir="${APT_SOURCES_DIR:-/etc/apt/sources.list.d}"
seconds="${APT_UPDATE_SECONDS:-300}"
pause="${APT_UPDATE_PAUSE:-15}"

shopt -s nullglob
for source_file in "$sources_dir"/*; do
    [ -f "$source_file" ] || continue
    if grep -qE 'dl\.google\.com|packages\.microsoft\.com' "$source_file"; then
        echo "removing unused third-party apt source: ${source_file}"
        sudo rm -f "$source_file"
    fi
done

for attempt in 1 2 3; do
    status=0
    sudo timeout --kill-after=30 "$seconds" apt-get update || status=$?
    [ "$status" -eq 0 ] && exit 0
    if [ "$status" -eq 124 ] || [ "$status" -eq 137 ]; then
        echo "apt-get update was still running after ${seconds}s (attempt ${attempt} of 3)" >&2
    else
        echo "apt-get update failed with exit code ${status} (attempt ${attempt} of 3)" >&2
    fi
    [ "$attempt" -eq 3 ] || sleep "$pause"
done
exit 1

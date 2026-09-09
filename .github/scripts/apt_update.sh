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
set -euo pipefail

shopt -s nullglob
for source_file in /etc/apt/sources.list.d/*; do
    [ -f "$source_file" ] || continue
    if grep -qE 'dl\.google\.com|packages\.microsoft\.com' "$source_file"; then
        echo "removing unused third-party apt source: ${source_file}"
        sudo rm -f "$source_file"
    fi
done

sudo apt-get update

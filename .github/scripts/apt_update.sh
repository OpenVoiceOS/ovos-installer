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
# did not match its own Release file, and every Linux job here failed for hours. The
# failure looks alarming (eight unrelated jobs red at once) and says nothing about the
# change under test. Retrying does not help while the upstream index stays inconsistent.
#
# So the lists are removed before the update rather than retried around.
set -euo pipefail

sudo rm -f /etc/apt/sources.list.d/google-chrome.list \
    /etc/apt/sources.list.d/microsoft-prod.list

sudo apt-get update

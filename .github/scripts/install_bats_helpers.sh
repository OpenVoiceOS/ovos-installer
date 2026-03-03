#!/usr/bin/env bash
set -euo pipefail

helpers_dir="${HOME}/shell-testing/test_helper"
mkdir -p "$helpers_dir"
rm -rf "${helpers_dir}/bats-support" "${helpers_dir}/bats-assert"

git clone --depth 1 https://github.com/bats-core/bats-support.git "${helpers_dir}/bats-support"
git clone --depth 1 https://github.com/bats-core/bats-assert.git "${helpers_dir}/bats-assert"

#!/usr/bin/env bash
set -euo pipefail

helpers_dir="${HOME}/shell-testing/test_helper"
bats_support_ref="${BATS_SUPPORT_REF:-v0.3.0}"
bats_assert_ref="${BATS_ASSERT_REF:-v2.1.0}"
mkdir -p "$helpers_dir"
rm -rf "${helpers_dir}/bats-support" "${helpers_dir}/bats-assert"

git clone --depth 1 --branch "$bats_support_ref" https://github.com/bats-core/bats-support.git "${helpers_dir}/bats-support"
git clone --depth 1 --branch "$bats_assert_ref" https://github.com/bats-core/bats-assert.git "${helpers_dir}/bats-assert"

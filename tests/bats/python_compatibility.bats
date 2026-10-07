#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE=/tmp/ovos-installer.log
}

@test "function_check_python_compatibility_allows_supported_version" {
    OVOS_VENV_PYTHON="3.11"
    run check_python_compatibility
    assert_success
}

@test "function_check_python_compatibility_allows_python_314_version" {
    OVOS_VENV_PYTHON="3.14"
    run check_python_compatibility
    assert_success
}

@test "function_check_python_compatibility_allows_python_314_executable" {
    OVOS_VENV_PYTHON="python3.14"
    run check_python_compatibility
    assert_success
}

# A python3.11 on the PATH whose sys.base_prefix is $2.
function fake_python311() {
    mkdir -p "$1"
    printf '#!/usr/bin/env bash\necho "%s"\n' "$2" >"$1/python3.11"
    chmod +x "$1/python3.11"
}

@test "function_check_python_compatibility_skips_the_python_the_install_put_in_local" {
    # uv's Python in ~/.local is the install's: the uninstall removes it, and an
    # installer virtualenv built on it lost its interpreter halfway through.
    RUN_AS_HOME="$(mktemp -d)"
    fake_python311 "$RUN_AS_HOME/.local/bin" "$RUN_AS_HOME/.local/share/uv/python/cpython-3.11.13-macos-aarch64-none"
    PATH="$RUN_AS_HOME/.local/bin:$PATH"
    OVOS_VENV_PYTHON="3.11"

    check_python_compatibility
    assert_equal "$PYTHON_CMD" "python3"
    assert_equal "$PYTHON" "3.11"
    rm -rf "$RUN_AS_HOME"
}

@test "function_check_python_compatibility_uses_a_python_of_the_systems_own" {
    RUN_AS_HOME="$(mktemp -d)"
    local elsewhere
    elsewhere="$(mktemp -d)"
    fake_python311 "$elsewhere" "/opt/homebrew/Cellar/python@3.11/3.11.13/Frameworks/Python.framework/Versions/3.11"
    PATH="$elsewhere:$PATH"
    OVOS_VENV_PYTHON="3.11"

    check_python_compatibility
    assert_equal "$PYTHON_CMD" "python3.11"
    rm -rf "$RUN_AS_HOME" "$elsewhere"
}

function teardown() {
    rm -f "$LOG_FILE"
    unset OVOS_VENV_PYTHON PYTHON
}

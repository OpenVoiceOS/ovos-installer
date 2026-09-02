#!/usr/bin/env bats
#
# Mitogen keeps one interpreter alive instead of starting a new one per task,
# which is worth roughly 4x less CPU on the task overhead of a local run. It
# only supports Ansible 10 on Python 3.11 and newer, though, and it works by
# patching Ansible internals, so what matters here is that the installer is
# strict about when it uses it and falls back rather than failing.

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"

    REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export REPO_ROOT
    LOG_FILE="$(mktemp)"
    export LOG_FILE
}

function teardown() {
    rm -f "$LOG_FILE"
}

# The gate on its own, without needing Ansible installed.
function gate() {
    local python_version="$1"
    local switch="$2"

    bash -c '
        cd "$REPO_ROOT"
        set +u
        ver() { printf "%03d" $(echo "$1" | tr "." " "); }
        PYTHON="'"$python_version"'"
        OVOS_INSTALLER_MITOGEN="'"$switch"'"
        source <(sed -n "/^function mitogen_is_supported/,/^}/p" utils/common.sh)
        if mitogen_is_supported; then printf mitogen; else printf stock; fi
    '
}

@test "mitogen: used on the interpreters it supports" {
    assert_equal "$(gate 3.11 true)" "mitogen"
    assert_equal "$(gate 3.12 true)" "mitogen"
    assert_equal "$(gate 3.14 true)" "mitogen"
}

@test "mitogen: not used below the version it supports Ansible 10 on" {
    # The installer still runs on these, on Ansible's own strategy.
    assert_equal "$(gate 3.10 true)" "stock"
    assert_equal "$(gate 3.9 true)" "stock"
}

@test "mitogen: the kill switch wins over a supported interpreter" {
    assert_equal "$(gate 3.12 false)" "stock"
}

@test "mitogen: an unknown interpreter is not assumed to be supported" {
    assert_equal "$(gate "" true)" "stock"
}

@test "mitogen: the pin travels with the Ansible pin it patches" {
    # Mitogen patches Ansible internals, so an unpinned pair would let a
    # background upgrade of either one land on users unannounced.
    run grep -E '^export MITOGEN_VERSION="[0-9]+\.[0-9]+\.[0-9]+"$' "$REPO_ROOT/utils/constants.sh"
    assert_success

    run grep -F -q 'mitogen==${MITOGEN_VERSION}' "$REPO_ROOT/utils/common.sh"
    assert_success
}

@test "mitogen: a run that cannot import it still installs" {
    # The speedup is worth having and never worth an install for, so an
    # unloadable plugin has to leave the strategy alone rather than abort.
    run bash -c '
        cd "$REPO_ROOT"
        set +u
        ver() { printf "%03d" $(echo "$1" | tr "." " "); }
        PYTHON="3.12"
        OVOS_INSTALLER_MITOGEN="true"
        VENV_PATH="$(mktemp -d)"
        mkdir -p "$VENV_PATH/bin"
        # An interpreter without the package installed.
        printf "#!/bin/sh\nexit 1\n" >"$VENV_PATH/bin/python3"
        chmod +x "$VENV_PATH/bin/python3"

        source <(sed -n "/^function mitogen_is_supported/,/^}/p" utils/common.sh)
        source <(sed -n "/^function configure_ansible_strategy/,/^}/p" utils/common.sh)

        configure_ansible_strategy
        printf "rc=%s strategy=%s\n" "$?" "${ANSIBLE_STRATEGY:-unset}"
    '

    assert_success
    assert_output "rc=0 strategy=unset"
}

@test "mitogen: a working install is pointed at the strategy plugin" {
    run bash -c '
        cd "$REPO_ROOT"
        set +u
        ver() { printf "%03d" $(echo "$1" | tr "." " "); }
        PYTHON="3.12"
        OVOS_INSTALLER_MITOGEN="true"
        VENV_PATH="$(mktemp -d)"
        mkdir -p "$VENV_PATH/bin"
        plugins="$(mktemp -d)/strategy"
        mkdir -p "$plugins"
        printf "#!/bin/sh\nprintf %%s \"%s\"\n" "$plugins" >"$VENV_PATH/bin/python3"
        chmod +x "$VENV_PATH/bin/python3"

        source <(sed -n "/^function mitogen_is_supported/,/^}/p" utils/common.sh)
        source <(sed -n "/^function configure_ansible_strategy/,/^}/p" utils/common.sh)

        configure_ansible_strategy
        printf "%s|%s\n" "${ANSIBLE_STRATEGY:-unset}" "${ANSIBLE_STRATEGY_PLUGINS:+set}"
    '

    assert_success
    assert_output "mitogen_linear|set"
}

@test "mitogen: the strategy is chosen after the interpreter it will start" {
    # Mitogen starts ANSIBLE_PYTHON_INTERPRETER and keeps it, so deciding the
    # strategy before that is settled would pin the wrong interpreter.
    local file="$REPO_ROOT/setup.sh"

    run bash -c "
        interpreter=\$(grep -n 'ANSIBLE_PYTHON_INTERPRETER=' '$file' | tail -n1 | cut -d: -f1)
        strategy=\$(grep -n 'configure_ansible_strategy' '$file' | head -n1 | cut -d: -f1)
        [ -n \"\$interpreter\" ] && [ -n \"\$strategy\" ] && [ \"\$interpreter\" -lt \"\$strategy\" ]
    "
    assert_success
}

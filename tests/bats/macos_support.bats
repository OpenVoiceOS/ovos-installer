#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/constants.sh
    load ../../utils/common.sh
    LOG_FILE="$BATS_TMPDIR/ovos-installer.log"
    : >"$LOG_FILE"
}

@test "function_run_as_target_user_executes_directly_when_user_matches" {
    RUN_AS="installer"
    function id() {
        if [ "$1" == "-un" ]; then
            echo "installer"
        else
            command id "$@"
        fi
    }
    export -f id

    run run_as_target_user printf "direct"
    assert_success
    assert_output "direct"

    unset -f id
}

@test "function_run_as_target_user_uses_sudo_for_different_user" {
    RUN_AS="ovos"
    local sudo_calls="${BATS_TMPDIR}/sudo-calls.log"
    : >"$sudo_calls"

    function id() {
        if [ "$1" == "-un" ]; then
            echo "root"
        else
            command id "$@"
        fi
    }
    function sudo() {
        printf '%s\n' "$*" >>"$sudo_calls"
        shift 3
        "$@"
    }
    export -f id sudo

    run run_as_target_user printf "sudo-path"
    assert_success
    assert_output "sudo-path"

    run cat "$sudo_calls"
    assert_output --partial "-H -u ovos printf sudo-path"

    unset -f id sudo
}

@test "function_resolve_brew_binary_from_path" {
    local brew_dir="${BATS_TMPDIR}/brew/bin"
    local fake_brew="${brew_dir}/brew"
    mkdir -p "$brew_dir"
    cat <<'EOF' >"$fake_brew"
#!/usr/bin/env bash
exit 0
EOF
    chmod +x "$fake_brew"

    PATH="${brew_dir}:$PATH"
    run resolve_brew_binary
    assert_success
    assert_output "$fake_brew"
}

@test "function_install_macos_packages_requires_non_root_run_as" {
    RUN_AS="root"
    run install_macos_packages
    assert_failure

    run cat "$LOG_FILE"
    assert_output --partial "Homebrew package installation requires running the installer with sudo from a non-root account."
}

@test "function_install_macos_packages_fails_when_brew_missing" {
    RUN_AS="ovos"
    function ensure_macos_command_line_tools() {
        return 0
    }
    function resolve_brew_binary() {
        return 1
    }
    export -f ensure_macos_command_line_tools resolve_brew_binary

    run install_macos_packages
    assert_failure
    assert_output --partial "Homebrew is required on macOS. Install it from https://brew.sh/ and rerun the installer."

    unset -f ensure_macos_command_line_tools resolve_brew_binary
}

@test "function_install_macos_packages_installs_only_missing_formulas" {
    RUN_AS="ovos"
    local calls_log="${BATS_TMPDIR}/brew-calls.log"
    : >"$calls_log"

    function ensure_macos_command_line_tools() {
        return 0
    }
    function resolve_brew_binary() {
        echo "/opt/homebrew/bin/brew"
    }
    function run_as_target_user() {
        printf '%s\n' "$*" >>"$calls_log"
        case "$*" in
        *"list --formula python"*) return 1 ;;
        *"list --formula expect"*) return 1 ;;
        *"install python expect"*) return 0 ;;
        esac
        return 0
    }
    export -f ensure_macos_command_line_tools resolve_brew_binary run_as_target_user

    run install_macos_packages
    assert_success

    run cat "$calls_log"
    assert_output --partial "list --formula python"
    assert_output --partial "list --formula jq"
    assert_output --partial "list --formula expect"
    assert_output --partial "list --formula newt"
    assert_output --partial "install python expect"

    unset -f ensure_macos_command_line_tools resolve_brew_binary run_as_target_user
}

@test "function_install_macos_packages_returns_success_when_all_formulas_present" {
    RUN_AS="ovos"
    local calls_log="${BATS_TMPDIR}/brew-calls-all-present.log"
    : >"$calls_log"

    function ensure_macos_command_line_tools() {
        return 0
    }
    function resolve_brew_binary() {
        echo "/opt/homebrew/bin/brew"
    }
    function run_as_target_user() {
        printf '%s\n' "$*" >>"$calls_log"
        return 0
    }
    export -f ensure_macos_command_line_tools resolve_brew_binary run_as_target_user

    run install_macos_packages
    assert_success

    run cat "$calls_log"
    assert_output --partial "list --formula python"
    refute_output --partial " install "

    unset -f ensure_macos_command_line_tools resolve_brew_binary run_as_target_user
}

@test "function_install_macos_packages_fails_when_brew_install_fails" {
    RUN_AS="ovos"
    local calls_log="${BATS_TMPDIR}/brew-calls-install-fail.log"
    : >"$calls_log"

    function ensure_macos_command_line_tools() {
        return 0
    }
    function resolve_brew_binary() {
        echo "/opt/homebrew/bin/brew"
    }
    function run_as_target_user() {
        printf '%s\n' "$*" >>"$calls_log"
        case "$*" in
        *"list --formula python"*) return 1 ;;
        *"install python"*) return 1 ;;
        esac
        return 0
    }
    export -f ensure_macos_command_line_tools resolve_brew_binary run_as_target_user

    run install_macos_packages
    assert_failure
    assert_output --partial "Homebrew package installation failed for: python"

    unset -f ensure_macos_command_line_tools resolve_brew_binary run_as_target_user
}

@test "function_ensure_macos_command_line_tools_succeeds_when_configured" {
    function xcode-select() {
        if [ "$1" == "-p" ]; then
            echo "/Library/Developer/CommandLineTools"
            return 0
        fi
        return 1
    }
    export -f xcode-select

    run ensure_macos_command_line_tools
    assert_success

    unset -f xcode-select
}

@test "function_ensure_macos_command_line_tools_fails_when_missing" {
    function xcode-select() {
        return 1
    }
    export -f xcode-select

    run ensure_macos_command_line_tools
    assert_failure
    assert_output --partial "Xcode Command Line Tools are required on macOS."

    unset -f xcode-select
}

function teardown() {
    rm -f "$LOG_FILE"
}

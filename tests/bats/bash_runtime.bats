#!/usr/bin/env bats

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    load ../../utils/bash_runtime.sh
}

@test "function_bash_runtime_major_version_returns_detected_major" {
    local fake_dir="${BATS_TMPDIR}/bash-major"
    local fake_bash="${fake_dir}/bash"
    mkdir -p "$fake_dir"
    cat <<'EOF' >"$fake_bash"
#!/usr/bin/env sh
if [ "$1" = "-c" ]; then
  printf '5'
fi
EOF
    chmod +x "$fake_bash"

    run bash_runtime_major_version "$fake_bash"
    assert_success
    assert_output "5"
}

@test "function_resolve_bash_runtime_uses_path_candidate_on_linux" {
    local fake_dir="${BATS_TMPDIR}/linux-bash"
    local fake_bash="${fake_dir}/bash"
    mkdir -p "$fake_dir"
    cat <<'EOF' >"$fake_bash"
#!/usr/bin/env sh
if [ "$1" = "-c" ]; then
  printf '6'
fi
EOF
    chmod +x "$fake_bash"

    PATH="${fake_dir}:$PATH"
    function bash_runtime_detect_system() {
        echo Linux
    }
    export -f bash_runtime_detect_system

    run resolve_bash_runtime 4
    assert_success
    assert_output "$fake_bash"
    unset -f bash_runtime_detect_system
}

@test "function_resolve_bash_runtime_fails_when_version_is_too_old" {
    local fake_dir="${BATS_TMPDIR}/old-bash"
    local fake_bash="${fake_dir}/bash"
    mkdir -p "$fake_dir"
    cat <<'EOF' >"$fake_bash"
#!/usr/bin/env sh
if [ "$1" = "-c" ]; then
  printf '3'
fi
EOF
    chmod +x "$fake_bash"

    PATH="${fake_dir}:$PATH"
    function bash_runtime_detect_system() {
        echo Linux
    }
    export -f bash_runtime_detect_system

    run resolve_bash_runtime 4
    assert_failure
    assert_output ""
    unset -f bash_runtime_detect_system
}

@test "function_resolve_bash_runtime_prefers_macos_candidates_over_path" {
    local fake_dir="${BATS_TMPDIR}/darwin-bash"
    local path_bash="${fake_dir}/path/bash"
    local brew_first="${fake_dir}/brew-first/bash"
    local brew_second="${fake_dir}/brew-second/bash"
    mkdir -p "$(dirname "$path_bash")" "$(dirname "$brew_first")" "$(dirname "$brew_second")"

    cat <<'EOF' >"$path_bash"
#!/usr/bin/env sh
if [ "$1" = "-c" ]; then
  printf '9'
fi
EOF
    cat <<'EOF' >"$brew_first"
#!/usr/bin/env sh
if [ "$1" = "-c" ]; then
  printf '3'
fi
EOF
    cat <<'EOF' >"$brew_second"
#!/usr/bin/env sh
if [ "$1" = "-c" ]; then
  printf '5'
fi
EOF
    chmod +x "$path_bash" "$brew_first" "$brew_second"

    PATH="$(dirname "$path_bash"):$PATH"
    function bash_runtime_detect_system() {
        echo Darwin
    }
    function bash_runtime_macos_candidates() {
        printf '%s\n' "$brew_first" "$brew_second"
    }
    export -f bash_runtime_detect_system bash_runtime_macos_candidates

    run resolve_bash_runtime 4
    assert_success
    assert_output "$brew_second"

    unset -f bash_runtime_detect_system bash_runtime_macos_candidates
}

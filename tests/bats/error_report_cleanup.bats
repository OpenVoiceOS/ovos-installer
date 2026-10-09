#!/usr/bin/env bats
# BATS assertions and fixture commands execute in separate child processes.
# shellcheck disable=SC2030,SC2031

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    REPORT_CLEANUP_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export REPORT_CLEANUP_ROOT
    export REPORT_CLEANUP_DIR="$BATS_TEST_TMPDIR"
    cat >"$REPORT_CLEANUP_DIR/upload.sh" <<'SH'
#!/usr/bin/env bash
source "$REPORT_CLEANUP_ROOT/utils/constants.sh"
source "$REPORT_CLEANUP_ROOT/utils/common.sh"
export TMPDIR="$REPORT_CLEANUP_DIR"
export OVOS_INSTALLER_AUTO_REPORT=1 OVOS_INSTALLER_REPORT_FD=3
OVOS_INSTALLER_CURRENT_LOG=true
LOG_FILE="$REPORT_CLEANUP_DIR/log"
printf '%s\n' 'Only harmless fixture text; no network requests.' >"$LOG_FILE"
exec 3>"$REPORT_CLEANUP_DIR/receipt"
mode="$1"
function chmod() {
    # This runs directly in the upload subshell, before the curl substitution.
    export REPORT_UPLOAD_PID="$BASHPID"
    command chmod "$@"
}
function python3() {
    if [ "$1" = scripts/sanitize_error_log.py ]; then
        case "$mode" in
            sanitizer-failure) return 1 ;;
            sanitizer-*) kill -s "${mode#sanitizer-}" "$BASHPID" ;;
        esac
    fi
    command python3 "$@"
}
function curl() {
    local arg
    for arg in "$@"; do
        case "$arg" in content=\<*)
            [ -s "${arg#content=<}" ] || return 90
            printf '%s\n' "${arg#content=<}" >"$REPORT_CLEANUP_DIR/report-path"
            ;;
        esac
    done
    case "$mode" in
        upload-failure) return 60 ;;
        upload-*) kill -s "${mode#upload-}" "$REPORT_UPLOAD_PID"; return 1 ;;
        invalid-url) printf '%s\n' 'https://example.invalid/not-allowed'; return 0 ;;
    esac
    printf '%s\n' 'https://paste.uoi.io/fixture/'
}
trap 'printf "parent EXIT\n" >>"$REPORT_CLEANUP_DIR/parent-exit"' EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP
trap -p EXIT INT TERM HUP >"$REPORT_CLEANUP_DIR/traps-before"
if upload_wizard_logs >"$REPORT_CLEANUP_DIR/url"; then rc=0; else rc=$?; fi
trap -p EXIT INT TERM HUP >"$REPORT_CLEANUP_DIR/traps-after"
exit "$rc"
SH
}

function run_upload_fixture() {
    # Every signal case has a hard deadline; curl is always a local stub.
    run python3 -c '
import subprocess
import sys
result = subprocess.run(["bash", sys.argv[1], sys.argv[2]],
                        capture_output=True, text=True, timeout=5)
print(result.stdout, end="")
print(result.stderr, end="", file=sys.stderr)
raise SystemExit(result.returncode)
' "$REPORT_CLEANUP_DIR/upload.sh" "$1"
}

@test "automatic_report_cleans_every_return_path_without_changing_parent_traps" {
    local mode expected
    for mode in success upload-failure sanitizer-failure invalid-url; do
        rm -f "$REPORT_CLEANUP_DIR/parent-exit"
        expected=1
        [ "$mode" != success ] || expected=0
        run_upload_fixture "$mode"
        assert_equal "$status" "$expected"
        run cmp "$REPORT_CLEANUP_DIR/traps-before" "$REPORT_CLEANUP_DIR/traps-after"
        assert_success
        assert_equal "$(cat "$REPORT_CLEANUP_DIR/parent-exit")" 'parent EXIT'
        run compgen -G "$REPORT_CLEANUP_DIR/ovos-wizard-report.*"
        assert_failure
        if [ "$mode" = success ]; then
            assert_equal "$(cat "$REPORT_CLEANUP_DIR/url")" 'https://paste.uoi.io/fixture/'
        else
            [ ! -s "$REPORT_CLEANUP_DIR/url" ]
        fi
    done
}

@test "interrupting_report_sanitization_or_upload_removes_private_files_and_preserves_signal_status" {
    local stage signal expected
    for stage in sanitizer upload; do
        for signal in INT TERM HUP; do
            case "$signal" in INT) expected=130 ;; TERM) expected=143 ;; HUP) expected=129 ;; esac
            rm -f "$REPORT_CLEANUP_DIR/parent-exit" "$REPORT_CLEANUP_DIR/report-path"
            run_upload_fixture "$stage-$signal"
            assert_equal "$status" "$expected"
            [ ! -s "$REPORT_CLEANUP_DIR/url" ]
            if [ "$stage" = upload ]; then
                [ -s "$REPORT_CLEANUP_DIR/report-path" ]
                [ ! -e "$(cat "$REPORT_CLEANUP_DIR/report-path")" ]
            fi
            run compgen -G "$REPORT_CLEANUP_DIR/ovos-wizard-report.*"
            assert_failure
            run cmp "$REPORT_CLEANUP_DIR/traps-before" "$REPORT_CLEANUP_DIR/traps-after"
            assert_success
            assert_equal "$(cat "$REPORT_CLEANUP_DIR/parent-exit")" 'parent EXIT'
        done
    done
}

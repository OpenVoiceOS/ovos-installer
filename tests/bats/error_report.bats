#!/usr/bin/env bats
# BATS isolates each test; exported fixture functions run in child Bash.
# shellcheck disable=SC2030,SC2031,SC2329

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    REPORT_TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export REPORT_TEST_ROOT
    export REPORT_TEST_DIR="$BATS_TEST_TMPDIR"
    export TMPDIR="$REPORT_TEST_DIR"
    export PASTE_REPLY="https://paste.uoi.io/Ab9_-z/"
    export OVOS_INSTALLER_ASSUME_INTERACTIVE=true
    export OVOS_INSTALLER_REPORT_FD=3
    unset OVOS_INSTALLER_AUTO_REPORT
    printf '%s\n' 'fixture log, never sent over the network' >"$REPORT_TEST_DIR/log"
    function curl() {
        printf '%s\n' upload >>"$REPORT_TEST_DIR/uploads"
        printf '%s\n' "$@" >"$REPORT_TEST_DIR/curl-args"
        local arg
        for arg in "$@"; do
            case "$arg" in content=\<*)
                cp "${arg#content=<}" "$REPORT_TEST_DIR/payload"
                stat -c '%a' "${arg#content=<}" >"$REPORT_TEST_DIR/payload-mode"
                ;;
            esac
        done
        [ "${REPORT_TEST_CURL_FAIL:-}" != true ] || return 60
        printf '%s\n' "$PASTE_REPLY"
    }
    export -f curl
    cat >"$REPORT_TEST_DIR/failure.sh" <<'SH'
#!/usr/bin/env bash
source "$REPORT_TEST_ROOT/utils/constants.sh"
source "$REPORT_TEST_ROOT/utils/common.sh"
LOG_FILE="$REPORT_TEST_DIR/log"
ANSIBLE_LOG_FILE="$REPORT_TEST_DIR/stale-ansible"
OVOS_INSTALLER_CURRENT_LOG=false
if [ "${REPORT_TEST_STALE_LOG:-}" != true ]; then
    delete_log
    printf '%s\n' 'fresh fixture log, never sent over the network' >"$LOG_FILE"
    if [ "${REPORT_TEST_CREDENTIALS:-}" = true ]; then
        report_homeassistant_api_key='private-home-assistant-value'
        report_llm_api_key='private-llm-value'
        printf '%s\n' "$report_homeassistant_api_key" "$report_llm_api_key" >>"$LOG_FILE"
    fi
fi
if [ "${REPORT_TEST_NO_PYTHON:-}" = true ]; then
    function python3() { return 127; }
fi
if [ "${REPORT_TEST_SANITIZER_FAIL:-}" = true ]; then
    function python3() {
        if [ "$1" = -c ]; then command python3 "$@"; else return 1; fi
    }
fi
if [ "${REPORT_TEST_FORBID_PROMPT:-}" = true ]; then
    function ask_optin() {
        printf '%s\n' prompt >>"$REPORT_TEST_DIR/prompts"
        return 1
    }
fi
if [ "${REPORT_TEST_UPLOAD_FAIL:-}" = true ]; then
    function upload_logs() { return 1; }
fi
exec 3>&-
if [ "$1" = open ]; then exec 3>"$REPORT_TEST_DIR/report"; fi
if [ "$1" = readonly ]; then exec 3<"$REPORT_TEST_DIR/log"; fi
if [ "$2" = ansible ]; then
    ansible_rc=23
    # Exercise the actual post-playbook success/failure branch without installing.
    source <(sed -n '/^if \[ "$ansible_rc" -eq 0 \]; then/,$p' "$REPORT_TEST_ROOT/setup.sh")
else
    on_error
fi
SH
}

@test "a_consented_error_reports_only_the_paste_url_and_preserves_failure" {
    run bash "$REPORT_TEST_DIR/failure.sh" open early <<<'yes'
    assert_equal "$status" 1
    assert_output --partial "Please share this URL with us $PASTE_REPLY"
    assert_equal "$(cat "$REPORT_TEST_DIR/uploads")" upload
    printf '%s\n' "$PASTE_REPLY" >"$REPORT_TEST_DIR/expected"
    run cmp "$REPORT_TEST_DIR/expected" "$REPORT_TEST_DIR/report"
    assert_success
}

@test "declining_log_upload_never_uploads_or_reports_a_url" {
    run bash "$REPORT_TEST_DIR/failure.sh" open early <<<'no'
    assert_equal "$status" 1
    assert_output --partial 'Log upload skipped'
    [ ! -e "$REPORT_TEST_DIR/uploads" ]
    [ ! -s "$REPORT_TEST_DIR/report" ]
}

@test "real_terminal_consent_reports_without_an_interactive_override" {
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    run python3 - "$REPORT_TEST_DIR/failure.sh" <<'PY'
import os
import pty
import select
import subprocess
import sys
import time

master, slave = pty.openpty()
process = subprocess.Popen(["bash", sys.argv[1], "open", "early"],
                           stdin=slave, stdout=slave, stderr=slave)
os.close(slave)
output = b""
answered = False
deadline = time.monotonic() + 5
try:
    while process.poll() is None:
        if time.monotonic() > deadline:
            raise RuntimeError("The consent prompt did not finish")
        if not select.select([master], [], [], 0.1)[0]:
            continue
        try:
            output += os.read(master, 4096)
        except OSError:
            break
        if b"(yes/no)" in output and not answered:
            os.write(master, b"yes\n")
            answered = True
    result = process.wait(timeout=2)
    assert answered, output
    print(output.decode(), end="")
    raise SystemExit(result)
finally:
    if process.poll() is None:
        process.kill()
        process.wait()
    os.close(master)
PY
    assert_equal "$status" 1
    assert_output --partial 'Upload the log on https://paste.uoi.io website?'
    assert_equal "$(cat "$REPORT_TEST_DIR/uploads")" upload
    assert_equal "$(cat "$REPORT_TEST_DIR/report")" "$PASTE_REPLY"
}

@test "noninteractive_failure_and_eof_never_upload_or_report" {
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    run bash "$REPORT_TEST_DIR/failure.sh" open early <<<'yes'
    assert_equal "$status" 1
    assert_output --partial 'Log upload skipped'
    [ ! -e "$REPORT_TEST_DIR/uploads" ]
    [ ! -s "$REPORT_TEST_DIR/report" ]

    export OVOS_INSTALLER_ASSUME_INTERACTIVE=true
    run python3 - "$REPORT_TEST_DIR/failure.sh" <<'PY'
import subprocess
import sys

result = subprocess.run(["bash", sys.argv[1], "open", "early"], input="",
                        capture_output=True, text=True, timeout=3)
print(result.stdout, end="")
print(result.stderr, end="", file=sys.stderr)
raise SystemExit(result.returncode)
PY
    assert_equal "$status" 1
    assert_output --partial 'Log upload skipped'
    [ ! -e "$REPORT_TEST_DIR/uploads" ]
    [ ! -s "$REPORT_TEST_DIR/report" ]
}

@test "ansible_failure_asks_for_consent_before_uploading_and_reporting" {
    run bash "$REPORT_TEST_DIR/failure.sh" open ansible <<<'no'
    assert_equal "$status" 1
    assert_output --partial 'Log upload skipped'
    [ ! -e "$REPORT_TEST_DIR/uploads" ]
    [ ! -s "$REPORT_TEST_DIR/report" ]

    run bash "$REPORT_TEST_DIR/failure.sh" open ansible <<<'yes'
    assert_equal "$status" 1
    assert_output --partial "Please share this URL with us $PASTE_REPLY"
    assert_equal "$(cat "$REPORT_TEST_DIR/uploads")" upload
    assert_equal "$(cat "$REPORT_TEST_DIR/report")" "$PASTE_REPLY"
}

@test "only_exact_paste_urls_are_reported" {
    local reply
    for reply in \
        'http://paste.uoi.io/abc' \
        'https://paste.uoi.io.evil.example/abc' \
        'https://paste.uoi.io@evil.example/abc' \
        'https://user@paste.uoi.io/abc' \
        'https://paste.uoi.io:443/abc' \
        'https://paste.uoi.io/' \
        'https://paste.uoi.io/abc/raw' \
        'https://paste.uoi.io/abc?secret=value' \
        'https://paste.uoi.io/abc#fragment' \
        'https://paste.uoi.io/%61bc' \
        'https://paste.uoi.io/../abc' \
        'https://paste.uoi.io/abc"' \
        $'https://paste.uoi.io/abc\\' \
        ' https://paste.uoi.io/abc' \
        $'https://paste.uoi.io/abc\nhttps://paste.uoi.io/def' \
        $'https://paste.uoi.io/abc\r' \
        "https://paste.uoi.io/$(printf 'a%.0s' {1..129})"; do
        export PASTE_REPLY="$reply"
        run bash "$REPORT_TEST_DIR/failure.sh" open early <<<'yes'
        assert_equal "$status" 1
        [ ! -s "$REPORT_TEST_DIR/report" ]
    done

    PASTE_REPLY="https://paste.uoi.io/$(printf 'a%.0s' {1..128})"
    export PASTE_REPLY
    run bash "$REPORT_TEST_DIR/failure.sh" open early <<<'yes'
    assert_equal "$status" 1
    assert_equal "$(cat "$REPORT_TEST_DIR/report")" "$PASTE_REPLY"
}

@test "missing_invalid_and_closed_report_fd_keep_terminal_output_and_exit_code" {
    local descriptor
    for descriptor in '' 0 1 2 4 '03' '/tmp/anything'; do
        export OVOS_INSTALLER_REPORT_FD="$descriptor"
        run bash "$REPORT_TEST_DIR/failure.sh" open early <<<'yes'
        assert_equal "$status" 1
        assert_output --partial "Please share this URL with us $PASTE_REPLY"
        [ ! -s "$REPORT_TEST_DIR/report" ]
    done
    unset OVOS_INSTALLER_REPORT_FD
    run bash "$REPORT_TEST_DIR/failure.sh" open early <<<'yes'
    assert_equal "$status" 1
    [ ! -s "$REPORT_TEST_DIR/report" ]

    export OVOS_INSTALLER_REPORT_FD=3
    run bash "$REPORT_TEST_DIR/failure.sh" closed early <<<'yes'
    assert_equal "$status" 1
    assert_output --partial "Please share this URL with us $PASTE_REPLY"
    refute_output --partial 'Bad file descriptor'

    run bash "$REPORT_TEST_DIR/failure.sh" readonly early <<<'yes'
    assert_equal "$status" 1
    assert_output --partial "Please share this URL with us $PASTE_REPLY"
    refute_output --partial 'Bad file descriptor'
}

@test "an_unsuccessful_upload_never_reports_a_url" {
    # Stub only the uploader: an empty upload result must not trigger a report.
    export REPORT_TEST_UPLOAD_FAIL=true
    run bash "$REPORT_TEST_DIR/failure.sh" open early <<<'yes'
    assert_equal "$status" 1
    assert_output --partial 'Failed to upload logs automatically'
    [ ! -s "$REPORT_TEST_DIR/report" ]
}

@test "wizard_failure_uploads_once_without_a_prompt_or_stdin" {
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    export OVOS_INSTALLER_AUTO_REPORT=1
    export REPORT_TEST_FORBID_PROMPT=true
    local stage
    for stage in early ansible; do
        rm -f "$REPORT_TEST_DIR/uploads" "$REPORT_TEST_DIR/report"
        run bash "$REPORT_TEST_DIR/failure.sh" open "$stage" </dev/null
        assert_equal "$status" 1
        [ ! -e "$REPORT_TEST_DIR/prompts" ]
        assert_equal "$(cat "$REPORT_TEST_DIR/uploads")" upload
        assert_equal "$(cat "$REPORT_TEST_DIR/report")" "$PASTE_REPLY"
        assert_output --partial "Please share this URL with us $PASTE_REPLY"
    done
}

@test "invalid_automatic_reporting_flags_never_bypass_consent" {
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    local flag
    for flag in '' 0 true yes 01 '1 ' ' 1'; do
        export OVOS_INSTALLER_AUTO_REPORT="$flag"
        run bash "$REPORT_TEST_DIR/failure.sh" open early </dev/null
        assert_equal "$status" 1
        assert_output --partial 'Log upload skipped'
        [ ! -e "$REPORT_TEST_DIR/uploads" ]
        [ ! -s "$REPORT_TEST_DIR/report" ]
    done
}

@test "automatic_reporting_requires_the_fixed_writable_descriptor" {
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    export OVOS_INSTALLER_AUTO_REPORT=1
    local descriptor
    for descriptor in '' 0 1 2 4 '03' '/tmp/anything'; do
        export OVOS_INSTALLER_REPORT_FD="$descriptor"
        run bash "$REPORT_TEST_DIR/failure.sh" open early </dev/null
        assert_equal "$status" 1
        [ ! -e "$REPORT_TEST_DIR/uploads" ]
        [ ! -s "$REPORT_TEST_DIR/report" ]
    done
    export OVOS_INSTALLER_REPORT_FD=3
    local access
    for access in closed readonly; do
        run bash "$REPORT_TEST_DIR/failure.sh" "$access" early </dev/null
        assert_equal "$status" 1
        assert_output --partial 'Failed to upload logs automatically'
        refute_output --partial 'Bad file descriptor'
        [ ! -e "$REPORT_TEST_DIR/uploads" ]
        [ ! -s "$REPORT_TEST_DIR/report" ]
    done
}

@test "failed_automatic_upload_preserves_the_installation_failure" {
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    export OVOS_INSTALLER_AUTO_REPORT=1
    export REPORT_TEST_FORBID_PROMPT=true
    export REPORT_TEST_CURL_FAIL=true
    run bash "$REPORT_TEST_DIR/failure.sh" open early </dev/null
    assert_equal "$status" 1
    assert_output --partial 'Failed to upload logs automatically'
    [ ! -e "$REPORT_TEST_DIR/prompts" ]
    [ ! -s "$REPORT_TEST_DIR/report" ]
}

@test "automatic_upload_is_strict_bounded_private_and_excludes_previous_ansible_logs" {
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    export OVOS_INSTALLER_AUTO_REPORT=1
    printf '%s\n' 'stale previous attempt secrets' >"$REPORT_TEST_DIR/stale-ansible"
    run bash "$REPORT_TEST_DIR/failure.sh" open early </dev/null
    assert_equal "$status" 1
    assert_equal "$(cat "$REPORT_TEST_DIR/uploads")" upload
    assert_equal "$(cat "$REPORT_TEST_DIR/payload-mode")" 600
    run cat "$REPORT_TEST_DIR/payload"
    assert_output --partial 'fresh fixture log'
    refute_output --partial 'stale previous attempt secrets'
    run cat "$REPORT_TEST_DIR/curl-args"
    assert_line --index 0 '-q'
    assert_line '=https'
    assert_line 'https://paste.uoi.io/api/'
    refute_line '-k'
    refute_line '-L'
}

@test "automatic_upload_never_sends_stale_logs_or_bypasses_a_missing_sanitizer" {
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    export OVOS_INSTALLER_AUTO_REPORT=1
    export REPORT_TEST_FORBID_PROMPT=true
    local condition
    for condition in REPORT_TEST_STALE_LOG REPORT_TEST_NO_PYTHON REPORT_TEST_SANITIZER_FAIL; do
        export "$condition"=true
        run bash "$REPORT_TEST_DIR/failure.sh" open early </dev/null
        assert_equal "$status" 1
        assert_output --partial 'Failed to upload logs automatically'
        [ ! -e "$REPORT_TEST_DIR/uploads" ]
        [ ! -e "$REPORT_TEST_DIR/prompts" ]
        [ ! -s "$REPORT_TEST_DIR/report" ]
        unset "$condition"
    done
}

@test "automatic_payload_filters_retained_credential_values_and_removes_temporary_file" {
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    export OVOS_INSTALLER_AUTO_REPORT=1
    export REPORT_TEST_CREDENTIALS=true
    run bash "$REPORT_TEST_DIR/failure.sh" open early </dev/null
    assert_equal "$status" 1
    run cat "$REPORT_TEST_DIR/payload"
    assert_output --partial '[redacted]'
    refute_output --partial 'private-home-assistant-value'
    refute_output --partial 'private-llm-value'
    run compgen -G "$REPORT_TEST_DIR/ovos-wizard-report.*"
    assert_failure
}

@test "automatic_upload_rejects_untrusted_response_urls_without_retrying" {
    unset OVOS_INSTALLER_ASSUME_INTERACTIVE
    export OVOS_INSTALLER_AUTO_REPORT=1
    export PASTE_REPLY='https://example.invalid/private'
    run bash "$REPORT_TEST_DIR/failure.sh" open early </dev/null
    assert_equal "$status" 1
    assert_output --partial 'Failed to upload logs automatically'
    refute_output --partial "$PASTE_REPLY"
    assert_equal "$(cat "$REPORT_TEST_DIR/uploads")" upload
    [ ! -s "$REPORT_TEST_DIR/report" ]
    run compgen -G "$REPORT_TEST_DIR/ovos-wizard-report.*"
    assert_failure
}

#!/usr/bin/env bats
# BATS isolates each test; exported fixture functions run in child Bash.
# shellcheck disable=SC2030,SC2031,SC2329

function setup() {
    load "$HOME/shell-testing/test_helper/bats-support/load"
    load "$HOME/shell-testing/test_helper/bats-assert/load"
    REPORT_TEST_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
    export REPORT_TEST_ROOT
    export REPORT_TEST_DIR="$BATS_TEST_TMPDIR"
    export PASTE_REPLY="https://paste.uoi.io/Ab9_-z/"
    export OVOS_INSTALLER_ASSUME_INTERACTIVE=true
    export OVOS_INSTALLER_REPORT_FD=3
    printf '%s\n' 'fixture log, never sent over the network' >"$REPORT_TEST_DIR/log"
    function curl() {
        printf '%s\n' upload >>"$REPORT_TEST_DIR/uploads"
        printf '%s\n' "$PASTE_REPLY"
    }
    export -f curl
    cat >"$REPORT_TEST_DIR/failure.sh" <<'SH'
#!/usr/bin/env bash
source "$REPORT_TEST_ROOT/utils/constants.sh"
source "$REPORT_TEST_ROOT/utils/common.sh"
LOG_FILE="$REPORT_TEST_DIR/log"
ANSIBLE_LOG_FILE=""
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

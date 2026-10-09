"""Offline regression coverage for automatic wizard report sanitization."""

import json
import os
import subprocess
import sys
from pathlib import Path
from urllib.parse import quote

import pytest

from sanitize_error_log import MAX_BYTES, bounded_log, sanitize


def test_known_secrets_and_encoded_values_are_removed() -> None:
    """Credential values are removed even without a nearby field name."""
    key = 'private:secret/with "quotes"'
    text = "\n".join((key, quote(key, safe=""), json.dumps(key)[1:-1]))
    assert sanitize(text, {"LLM_API_KEY": key}) == "[redacted]\n[redacted]\n[redacted]"


@pytest.mark.parametrize("text", [
    'HOMEASSISTANT_API_KEY=private-value',
    '{"ovos_installer_llm_api_key": "private-value"}',
    'Authorization: Bearer private-value',
    'password: private-value',
    'accessToken: private-value',
    'clientSecret: private-value',
    'client.password: private-value',
    'satellite_key: private-value',
    'curl https://example.org/?access_token=private-value',
    'secret = private-value',
    'curl https://example.org/?key=private-value',
    'curl https://example.org/?api_key=private%20value',
    'api\x1b[31m_key: private-value',
])
def test_credential_fields_are_removed(text: str) -> None:
    """Shell, JSON, YAML, HTTP and query forms lose their whole secret line."""
    assert sanitize(text + "\nuseful error\n", {}) == "[redacted]\nuseful error\n"


def test_url_userinfo_bearer_and_private_key_are_removed() -> None:
    """Common credentials without assignment syntax do not survive."""
    text = ("fetch https://user:pass@example.org/repo\n"
            "received Bearer abc.def-ghi\n"
            "-----BEGIN RSA PRIVATE KEY-----\nprivate-body\n"
            "-----END RSA PRIVATE KEY-----\n")
    result = sanitize(text, {})
    assert "user:pass" not in result
    assert "abc.def-ghi" not in result
    assert "private-body" not in result
    assert "example.org/repo" in result


def test_bounded_tail_discards_partial_credential_line(tmp_path: Path) -> None:
    """A secret whose field name lies outside the byte window is dropped."""
    path = tmp_path / "log"
    path.write_text("api_key=" + "x" * 100 + "\nuseful error\n")
    assert bounded_log(str(path), 32) == "useful error\n"


@pytest.mark.parametrize("limit", [0, -1, MAX_BYTES + 1])
def test_invalid_limits_fail_closed(tmp_path: Path, limit: int) -> None:
    """An inherited size setting cannot disable the report's hard bound."""
    path = tmp_path / "log"
    path.write_text("data")
    with pytest.raises(ValueError):
        bounded_log(str(path), limit)


def test_symlinks_and_fifos_fail_closed(tmp_path: Path) -> None:
    """A log cannot redirect reads to a different file or block reporting."""
    regular = tmp_path / "log"
    regular.write_text("data")
    linked = tmp_path / "link"
    linked.symlink_to(regular)
    fifo = tmp_path / "fifo"
    os.mkfifo(fifo)
    for path in (linked, fifo):
        with pytest.raises((OSError, ValueError)):
            bounded_log(str(path), 100)


def test_cli_never_emits_raw_log_after_failure(tmp_path: Path) -> None:
    """Invalid input exits unsuccessfully without printing its sensitive data."""
    path = tmp_path / "log"
    path.write_text("api_key=private-value\n")
    result = subprocess.run(
        [sys.executable, str(Path(__file__).with_name("sanitize_error_log.py")),
         str(path), "unlimited"], capture_output=True, check=False,
    )
    assert result.returncode == 1
    assert result.stdout == b""


def test_cli_keeps_output_within_cap_after_redaction(tmp_path: Path) -> None:
    """Expanding a short credential to the marker still respects the byte cap."""
    path = tmp_path / "log"
    path.write_text("xyz\n" * 20)
    result = subprocess.run(
        [sys.executable, str(Path(__file__).with_name("sanitize_error_log.py")),
         str(path), "40"], capture_output=True, check=False,
        env={**os.environ, "LLM_API_KEY": "xyz"},
    )
    assert result.returncode == 0
    assert 0 < len(result.stdout) <= 40
    assert b"xyz" not in result.stdout


def test_numeric_limits_are_not_treated_as_secret_values() -> None:
    """Token-count configuration does not erase matching diagnostics."""
    assert sanitize("waited 300 seconds", {"LLM_MAX_TOKENS": "300"}) == "waited 300 seconds"


@pytest.mark.parametrize("expression", [
    "'.' * 1500000", "'\\x1b]' * 750000", "'token' * 300000",
])
def test_large_unstructured_lines_do_not_stall_reporting(expression: str) -> None:
    """Malformed output must not trigger quadratic credential matching."""
    script = ("from sanitize_error_log import sanitize; "
              f"assert len(sanitize({expression}, {{}})) <= 1500000")
    result = subprocess.run([sys.executable, "-c", script],
                            cwd=Path(__file__).parent, capture_output=True,
                            check=False, timeout=5)
    assert result.returncode == 0, result.stderr

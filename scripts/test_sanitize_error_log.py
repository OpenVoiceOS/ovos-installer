"""Offline regression coverage for automatic wizard report sanitization."""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from urllib.parse import quote

from sanitize_error_log import MAX_BYTES, bounded_log, sanitize

SANITIZER = Path(__file__).with_name("sanitize_error_log.py")


class SanitizeTests(unittest.TestCase):
    def test_known_secrets_and_encoded_values_are_removed(self) -> None:
        """Credential values are removed even without a nearby field name."""
        key = 'private:secret/with "quotes"'
        text = "\n".join((key, quote(key, safe=""), json.dumps(key)[1:-1]))
        self.assertEqual(sanitize(text, {"LLM_API_KEY": key}),
                         "[redacted]\n[redacted]\n[redacted]")

    def test_credential_fields_are_removed(self) -> None:
        """Shell, JSON, YAML, HTTP and query forms lose their whole secret line."""
        for text in (
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
        ):
            with self.subTest(text=text):
                self.assertEqual(sanitize(text + "\nuseful error\n", {}),
                                 "[redacted]\nuseful error\n")

    def test_url_userinfo_bearer_and_private_key_are_removed(self) -> None:
        """Common credentials without assignment syntax do not survive."""
        text = ("fetch https://user:pass@example.org/repo\n"
                "received Bearer abc.def-ghi\n"
                "-----BEGIN RSA PRIVATE KEY-----\nprivate-body\n"
                "-----END RSA PRIVATE KEY-----\n")
        result = sanitize(text, {})
        self.assertNotIn("user:pass", result)
        self.assertNotIn("abc.def-ghi", result)
        self.assertNotIn("private-body", result)
        self.assertIn("example.org/repo", result)

    def test_numeric_limits_are_not_treated_as_secret_values(self) -> None:
        """Token-count configuration does not erase matching diagnostics."""
        self.assertEqual(sanitize("waited 300 seconds", {"LLM_MAX_TOKENS": "300"}),
                         "waited 300 seconds")

    def test_large_unstructured_lines_do_not_stall_reporting(self) -> None:
        """Malformed output must not trigger quadratic credential matching."""
        for expression in ("'.' * 1500000", "'\\x1b]' * 750000", "'token' * 300000"):
            with self.subTest(expression=expression):
                script = ("from sanitize_error_log import sanitize; "
                          f"assert len(sanitize({expression}, {{}})) <= 1500000")
                result = subprocess.run([sys.executable, "-c", script],
                                        cwd=Path(__file__).parent, capture_output=True,
                                        check=False, timeout=5)
                self.assertEqual(result.returncode, 0, result.stderr)


class BoundedLogTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self._tmp.cleanup)
        self.tmp_path = Path(self._tmp.name)

    def test_bounded_tail_discards_partial_credential_line(self) -> None:
        """A secret whose field name lies outside the byte window is dropped."""
        path = self.tmp_path / "log"
        path.write_text("api_key=" + "x" * 100 + "\nuseful error\n")
        self.assertEqual(bounded_log(str(path), 32), "useful error\n")

    def test_invalid_limits_fail_closed(self) -> None:
        """An inherited size setting cannot disable the report's hard bound."""
        path = self.tmp_path / "log"
        path.write_text("data")
        for limit in (0, -1, MAX_BYTES + 1):
            with self.subTest(limit=limit), self.assertRaises(ValueError):
                bounded_log(str(path), limit)

    def test_symlinks_and_fifos_fail_closed(self) -> None:
        """A log cannot redirect reads to a different file or block reporting."""
        regular = self.tmp_path / "log"
        regular.write_text("data")
        linked = self.tmp_path / "link"
        linked.symlink_to(regular)
        fifo = self.tmp_path / "fifo"
        os.mkfifo(fifo)
        for path in (linked, fifo):
            with self.subTest(path=path.name), self.assertRaises((OSError, ValueError)):
                bounded_log(str(path), 100)

    def test_cli_never_emits_raw_log_after_failure(self) -> None:
        """Invalid input exits unsuccessfully without printing its sensitive data."""
        path = self.tmp_path / "log"
        path.write_text("api_key=private-value\n")
        result = subprocess.run([sys.executable, str(SANITIZER), str(path), "unlimited"],
                                capture_output=True, check=False)
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, b"")

    def test_cli_keeps_output_within_cap_after_redaction(self) -> None:
        """Expanding a short credential to the marker still respects the byte cap."""
        path = self.tmp_path / "log"
        path.write_text("xyz\n" * 20)
        result = subprocess.run([sys.executable, str(SANITIZER), str(path), "40"],
                                capture_output=True, check=False,
                                env={**os.environ, "LLM_API_KEY": "xyz"})
        self.assertEqual(result.returncode, 0)
        self.assertTrue(0 < len(result.stdout) <= 40)
        self.assertNotIn(b"xyz", result.stdout)


if __name__ == "__main__":
    unittest.main()

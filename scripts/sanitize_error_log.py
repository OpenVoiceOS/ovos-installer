"""Prepare a bounded, credential-redacted log for an automatic wizard report."""

import json
import os
import re
import stat
import sys
from typing import Mapping
from urllib.parse import quote, quote_plus


MAX_BYTES = 1_500_000
REDACTED = "[redacted]"
SECRET_NAME = re.compile(
    r"(?i)(?:^|[_-])(?:api[_-]?key|token|password|passwd|secret|authorization|cookie|"
    r"credentials?|satellite[_-]key)(?:$|[_-])"
)
SECRET_FIELD_NAME = re.compile(
    r"(?i)(?:api[_-]?key|token|password|passwd|secret|authorization|cookie|credential|satellite[_-]key)"
)
ASSIGNMENT = re.compile(r"(?<![\w.-])[\"']?([\w.-]+)[\"']?\s*[:=]")


def has_secret_field(line: str) -> bool:
    """Parse assignment keys once instead of backtracking over credential names."""
    return any(
        match.group(1).lower() == "key" or SECRET_FIELD_NAME.search(match.group(1))
        for match in ASSIGNMENT.finditer(line)
    )



def bounded_log(path: str, limit: int) -> str:
    """Read a complete regular file within the cap, or refuse the report.

    A tail may begin inside a multiline credential whose opening marker was
    omitted. Reject oversized logs rather than sanitize incomplete context.
    """
    if not 1 <= limit <= MAX_BYTES:
        raise ValueError("Invalid report size limit")
    descriptor = os.open(path, os.O_RDONLY | os.O_NONBLOCK | os.O_NOFOLLOW)
    with os.fdopen(descriptor, "rb") as source:
        metadata = os.fstat(source.fileno())
        if not stat.S_ISREG(metadata.st_mode):
            raise ValueError("The report source must be a regular file")
        if metadata.st_size > limit:
            raise ValueError("The complete report source exceeds the size limit")
        # Check again while reading in case the file grew after fstat(). The
        # sentinel byte keeps I/O bounded while detecting a truncated read.
        data = source.read(limit + 1)
    if len(data) > limit:
        raise ValueError("The complete report source exceeds the size limit")
    return data.decode("utf-8", "replace")


def sanitize(text: str, environment: Mapping[str, str]) -> str:
    """Remove known secret values and common credential syntax from log text."""
    text = re.sub(r"\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07\x1b]*(?:\x07|\x1b\\))", "", text)
    secrets = set()
    for name, value in environment.items():
        if value and not name.startswith("BASH_FUNC_") and SECRET_NAME.search(name):
            secrets.update((value, quote(value, safe=""), quote_plus(value),
                            json.dumps(value)[1:-1]))
    for value in sorted(secrets, key=len, reverse=True):
        text = text.replace(value, REDACTED)
    text = re.sub(
        r"-----BEGIN (?:[A-Z0-9 ]* )?PRIVATE KEY-----.*?"
        r"(?:-----END (?:[A-Z0-9 ]* )?PRIVATE KEY-----|\Z)",
        REDACTED, text, flags=re.DOTALL,
    )
    text = re.sub(r"(?i)\b(https?://)[^\s/@]+@", r"\1[redacted]@", text)
    text = re.sub(r"(?i)\bBearer\s+[A-Za-z0-9._~+/=-]+", "Bearer " + REDACTED, text)
    text = re.sub(r"\beyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\b", REDACTED, text)
    return "".join(
        REDACTED + "\n" if has_secret_field(line) else line
        for line in text.splitlines(keepends=True)
    )


def main() -> int:
    """Write a sanitized report, or fail without emitting raw log contents."""
    try:
        path, requested_limit = sys.argv[1:]
        limit = int(requested_limit)
        report = sanitize(bounded_log(path, limit), os.environ).encode("utf-8")
        if len(report) > limit:
            report = report[-limit:].partition(b"\n")[2]
        if not report.strip():
            return 1
        sys.stdout.buffer.write(report)
        return 0
    except (OSError, ValueError):
        return 1


if __name__ == "__main__":
    raise SystemExit(main())

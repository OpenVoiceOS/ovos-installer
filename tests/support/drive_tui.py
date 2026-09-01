#!/usr/bin/env python3
"""Drive the installer TUI through the real whiptail binary.

The bats suite stubs whiptail, which is what makes it fast and portable, but it
means nothing checks how whiptail itself behaves: that it draws the buttons at
the size it is given, that the cancel button is where "Back" is wired, or that
ESC does nothing (it stopped being a newt form hotkey in 0.52.5). This runs the
flow in a pseudo terminal of a chosen size and reports the screens it saw.

Usage: drive_tui.py <rows> <columns> <key>[,<key>...] ...
Keys are "enter", "tab" or "esc"; each argument is one step of the walk.
Prints one line per step: "<step>\t<screen title>".
"""

import fcntl
import os
import pty
import re
import select
import signal
import struct
import sys
import termios
import time

ESCAPE_SEQUENCE = re.compile(r"\x1b\[[0-9;?]*[A-Za-z]|\x1b[()][B0]|\x1b\[[0-9;]*t|\x1b[>=]")
KEYS = {"enter": b"\r", "tab": b"\t", "esc": b"\x1b", "space": b" "}

# Every screen the walk can land on, longest first so that "Usage Metrics" is
# not reported as "Metrics".
TITLES = [
    "Open Voice OS Installation - Usage Metrics",
    "Open Voice OS Installation - Uninstall",
    "Open Voice OS Installation - Telemetry",
    "Open Voice OS Installation - Language",
    "Open Voice OS Installation - Detected",
    "Open Voice OS Installation - Channels",
    "Open Voice OS Installation - Profiles",
    "Open Voice OS Installation - Features",
    "Open Voice OS Installation - Methods",
    "Open Voice OS Installation - Summary",
    "Open Voice OS Installation - Welcome",
    "Open Voice OS Installation - Update",
    "Open Voice OS Installation - Quit",
]


def spawn(rows, columns, harness):
    pid, fd = pty.fork()
    if pid == 0:
        os.environ["TERM"] = "xterm"
        os.execvp("bash", ["bash", harness])
    fcntl.ioctl(fd, termios.TIOCSWINSZ, struct.pack("HHHH", rows, columns, 0, 0))
    return pid, fd


def read_for(fd, seconds):
    chunks = []
    deadline = time.time() + seconds
    while time.time() < deadline:
        readable, _, _ = select.select([fd], [], [], 0.15)
        if not readable:
            continue
        try:
            chunk = os.read(fd, 65536)
        except OSError:
            break
        if not chunk:
            break
        chunks.append(chunk.decode(errors="replace"))
    return ESCAPE_SEQUENCE.sub("", "".join(chunks))


def last_title(screen):
    seen = [(screen.rfind(title), title) for title in TITLES]
    position, title = max(seen)
    return title if position >= 0 else ""


def main():
    rows, columns, harness = int(sys.argv[1]), int(sys.argv[2]), sys.argv[3]
    steps = sys.argv[4:]

    pid, fd = spawn(rows, columns, harness)
    try:
        screen = read_for(fd, 2.5)
        print(f"start\t{last_title(screen)}")

        for step in steps:
            for key in step.split(","):
                os.write(fd, KEYS[key])
                time.sleep(0.25)
            screen = read_for(fd, 1.4)
            print(f"{step}\t{last_title(screen)}")

        screen += read_for(fd, 1.5)
        if "REACHED_END" in screen:
            print("end\tREACHED_END")
    finally:
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Render the installer screens in docs/images from the TUI itself.

The screenshots in the README are the only picture most people get of the
installer before they run it, so they have to match what it actually draws.
Rather than asking someone to take them by hand, this walks the flow in a
pseudo terminal, reads what whiptail paints, and renders that to a PNG.

Requires whiptail and Pillow. Run from the repository root:

    python3 scripts/render_screenshots.py
"""

import fcntl
import os
import pty
import re
import select
import signal
import struct
import subprocess
import sys
import termios
import time
import unicodedata

from PIL import Image, ImageDraw, ImageFont

COLUMNS = 100
ROWS = 44
CELL_WIDTH = 11
CELL_HEIGHT = 22
FONT_SIZE = 19

# Asked of fontconfig in order, because the path a distribution puts a font at
# is its own business. Pillow silently falls back to searching by basename when
# a path does not exist, which hides a missing font, so the paths are resolved
# here instead.
FONT_FAMILIES = ["Liberation Mono", "DejaVu Sans Mono", "Noto Sans Mono", "monospace"]
EMOJI_FAMILIES = ["Noto Emoji", "Symbola", "DejaVu Sans"]
SAMPLE_EMOJI = "\U0001F31F"

# The palette NEWT_COLORS is written against, in the shades the terminal in the
# original screenshots used.
PALETTE = {
    0: (0x26, 0x2A, 0x3A),   # black, the text on the dialogs
    1: (0xC1, 0x44, 0x3F),   # red, the titles
    2: (0x4E, 0x9A, 0x06),
    3: (0xC4, 0xA0, 0x00),
    4: (0x34, 0x65, 0xA4),
    5: (0x75, 0x50, 0x7B),
    6: (0x3A, 0x9A, 0xA8),   # cyan, the buttons
    7: (0xD0, 0xCF, 0xCC),   # light gray, the dialog background
    8: (0x7F, 0x7F, 0x8A),   # gray, the drop shadow
    9: (0xEF, 0x53, 0x50),
    10: (0x8A, 0xE2, 0x34),
    11: (0xFC, 0xE9, 0x4F),
    12: (0x72, 0x9F, 0xCF),
    13: (0xAD, 0x7F, 0xA8),
    14: (0x45, 0xA0, 0xAC),
    15: (0xFF, 0xFF, 0xFF),
}
ROOT_BACKGROUND = (0x1A, 0x1A, 0x26)

# Drawn as rectangles rather than glyphs so the borders join up cleanly.
BOX_CHARACTERS = {
    "─": ("left", "right"),
    "│": ("up", "down"),
    "┌": ("right", "down"),
    "┐": ("left", "down"),
    "└": ("right", "up"),
    "┘": ("left", "up"),
    "├": ("up", "down", "right"),
    "┤": ("up", "down", "left"),
    "┬": ("left", "right", "down"),
    "┴": ("left", "right", "up"),
    "┼": ("up", "down", "left", "right"),
}

CSI = re.compile(r"\x1b\[([0-9;?]*)([A-Za-z])")


def is_wide(character):
    """Whether a character takes two terminal cells, as emoji do."""
    return unicodedata.east_asian_width(character) in ("W", "F")


class Screen:
    """Just enough of a terminal to read back what newt painted."""

    def __init__(self, rows, columns):
        self.rows = rows
        self.columns = columns
        self.reset()

    def reset(self):
        self.cells = [
            [(" ", 7, 0, False) for _ in range(self.columns)] for _ in range(self.rows)
        ]
        self.row = 0
        self.column = 0
        self.foreground = 7
        self.background = 0
        self.bold = False

    def feed(self, data):
        index = 0
        while index < len(data):
            character = data[index]

            if character == "\x1b":
                match = CSI.match(data, index)
                if match:
                    self.control(match.group(1), match.group(2))
                    index = match.end()
                    continue
                # Charset selection and anything else single-character.
                index += 2 if index + 1 < len(data) and data[index + 1] in "()>=" else 1
                if index <= len(data) and data[index - 1] in "()":
                    index += 1
                continue

            if character == "\r":
                self.column = 0
            elif character == "\n":
                self.row = min(self.row + 1, self.rows - 1)
            elif character == "\x08":
                self.column = max(self.column - 1, 0)
            elif character >= " ":
                self.put(character)
            index += 1

    def put(self, character):
        width = 2 if is_wide(character) else 1

        if 0 <= self.row < self.rows and 0 <= self.column < self.columns:
            self.cells[self.row][self.column] = (
                character,
                self.foreground,
                self.background,
                self.bold,
            )
            # The second cell of a wide character is covered by the first.
            if width == 2 and self.column + 1 < self.columns:
                self.cells[self.row][self.column + 1] = (
                    " ",
                    self.foreground,
                    self.background,
                    self.bold,
                )

        self.column += width
        if self.column >= self.columns:
            self.column = self.columns - 1

    def control(self, parameters, final):
        if parameters.startswith("?"):
            return

        values = [int(value) for value in parameters.split(";") if value.isdigit()]

        if final == "H":
            self.row = (values[0] - 1) if values else 0
            self.column = (values[1] - 1) if len(values) > 1 else 0
            self.row = max(0, min(self.row, self.rows - 1))
            self.column = max(0, min(self.column, self.columns - 1))
        elif final == "J":
            self.reset()
        elif final == "K":
            for column in range(self.column, self.columns):
                self.cells[self.row][column] = (" ", self.foreground, self.background, self.bold)
        elif final == "m":
            self.select_graphics(values or [0])

    def select_graphics(self, values):
        for value in values:
            if value == 0:
                self.foreground, self.background, self.bold = 7, 0, False
            elif value == 1:
                self.bold = True
            elif value == 22:
                self.bold = False
            elif 30 <= value <= 37:
                self.foreground = value - 30
            elif 40 <= value <= 47:
                self.background = value - 40
            elif 90 <= value <= 97:
                self.foreground = value - 90 + 8
            elif 100 <= value <= 107:
                self.background = value - 100 + 8


def font_path(families):
    for family in families:
        try:
            path = subprocess.run(
                ["fc-match", "-f", "%{file}", family],
                capture_output=True, text=True, check=True,
            ).stdout.strip()
        except (OSError, subprocess.CalledProcessError):
            continue

        if path and os.path.exists(path):
            return path

    return None


def load_font():
    path = font_path(FONT_FAMILIES)
    if not path:
        raise SystemExit("no monospace font found; install liberation-mono or dejavu-sans-mono")
    return ImageFont.truetype(path, FONT_SIZE)


def load_emoji_font():
    """An emoji font that this Pillow can actually rasterise.

    Colour emoji are COLRv1 these days and not every Pillow build draws them,
    while fontconfig happily substitutes the colour font for the outline one.
    So the candidates are tried until one puts ink on the page; a terminal
    screenshot does not need them in colour.
    """
    for path in emoji_font_candidates():
        try:
            font = ImageFont.truetype(path, FONT_SIZE)
        except OSError:
            continue

        if font.getmask(SAMPLE_EMOJI, mode="L").getbbox() is not None:
            return font

    return None


def emoji_font_candidates():
    paths = []

    for family in EMOJI_FAMILIES:
        path = font_path([family])
        if path and path not in paths:
            paths.append(path)

    try:
        listed = subprocess.run(
            ["fc-list", "--format", "%{file}\n"], capture_output=True, text=True, check=True
        ).stdout.splitlines()
    except (OSError, subprocess.CalledProcessError):
        listed = []

    for path in listed:
        if "emoji" in path.lower() and path not in paths and os.path.exists(path):
            paths.append(path)

    return paths


def render(screen, path):
    font = load_font()
    emoji_font = load_emoji_font()
    image = Image.new("RGB", (COLUMNS * CELL_WIDTH, ROWS * CELL_HEIGHT), ROOT_BACKGROUND)
    draw = ImageDraw.Draw(image)

    for row_index, row in enumerate(screen.cells):
        for column_index, (character, foreground, background, bold) in enumerate(row):
            x = column_index * CELL_WIDTH
            y = row_index * CELL_HEIGHT
            background_colour = PALETTE.get(background, ROOT_BACKGROUND)
            if background == 0:
                background_colour = ROOT_BACKGROUND

            draw.rectangle([x, y, x + CELL_WIDTH - 1, y + CELL_HEIGHT - 1], fill=background_colour)

            if character == " ":
                continue

            colour = PALETTE.get(foreground + (8 if bold and foreground < 8 else 0), PALETTE[7])

            if character in BOX_CHARACTERS:
                draw_box(draw, x, y, colour, BOX_CHARACTERS[character])
                continue

            if is_wide(character):
                if emoji_font is not None:
                    draw.text((x, y + 1), character, font=emoji_font, fill=colour)
                continue

            draw.text((x, y + 1), character, font=font, fill=colour)

    image.save(path)


def draw_box(draw, x, y, colour, directions):
    middle_x = x + CELL_WIDTH // 2
    middle_y = y + CELL_HEIGHT // 2
    thickness = 1

    if "left" in directions:
        draw.rectangle([x, middle_y - thickness, middle_x, middle_y + thickness], fill=colour)
    if "right" in directions:
        draw.rectangle([middle_x, middle_y - thickness, x + CELL_WIDTH, middle_y + thickness], fill=colour)
    if "up" in directions:
        draw.rectangle([middle_x - thickness, y, middle_x + thickness, middle_y], fill=colour)
    if "down" in directions:
        draw.rectangle([middle_x - thickness, middle_y, middle_x + thickness, y + CELL_HEIGHT], fill=colour)


def capture(harness, keys, environment=None):
    screen = Screen(ROWS, COLUMNS)

    pid, descriptor = pty.fork()
    if pid == 0:
        os.environ["TERM"] = "xterm"
        os.environ.update(environment or {})
        os.execvp("bash", ["bash", harness])
    fcntl.ioctl(descriptor, termios.TIOCSWINSZ, struct.pack("HHHH", ROWS, COLUMNS, 0, 0))

    try:
        drain(descriptor, screen, 2.5)
        for key in keys:
            os.write(descriptor, b"\r" if key == "enter" else b"\t")
            time.sleep(0.25)
            drain(descriptor, screen, 1.4)
    finally:
        try:
            os.kill(pid, signal.SIGKILL)
        except ProcessLookupError:
            pass

    return screen


def drain(descriptor, screen, seconds):
    deadline = time.time() + seconds
    while time.time() < deadline:
        readable, _, _ = select.select([descriptor], [], [], 0.15)
        if not readable:
            continue
        try:
            chunk = os.read(descriptor, 65536)
        except OSError:
            return
        if not chunk:
            return
        screen.feed(chunk.decode(errors="replace"))


# Each screenshot is the flow walked forward with Enter until it lands there.
SCREENSHOTS = [
    ("screenshot_1.png", "tui_harness.sh", []),
    ("screenshot_2.png", "tui_harness.sh", ["enter"]),
    ("screenshot_3.png", "tui_harness.sh", ["enter"] * 2),
    ("screenshot_4.png", "tui_harness.sh", ["enter"] * 3),
    ("screenshot_5.png", "tui_harness.sh", ["enter"] * 4),
    ("screenshot_6.png", "tui_harness.sh", ["enter"] * 5),
    ("screenshot_7.png", "tui_harness.sh", ["enter"] * 6),
    ("screenshot_8.png", "finish_harness.sh", []),
]


def main():
    root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    os.chdir(root)
    os.environ["REPO_ROOT"] = root

    for name, harness, keys in SCREENSHOTS:
        screen = capture(os.path.join(root, "tests/support", harness), keys)
        destination = os.path.join(root, "docs/images", name)
        render(screen, destination)
        print(f"wrote {destination}")


if __name__ == "__main__":
    sys.exit(main())

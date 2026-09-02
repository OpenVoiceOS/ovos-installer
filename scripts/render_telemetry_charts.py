#!/usr/bin/env python3
"""Render the telemetry charts the README shows.

GitHub does not run JavaScript in a README, so the dashboard at
https://telemetry.smartgic.io/ovos-installer/dashboard/ cannot be embedded.
This fetches the same public summary the dashboard uses and renders plain SVG,
which a workflow commits on a schedule. Light and dark variants are generated
because GitHub picks between them with <picture>.

Usage:
    python3 scripts/render_telemetry_charts.py [--offline FILE]
"""

import argparse
import datetime as dt
import json
import os
import sys
import urllib.request

SUMMARY_URL = (
    "https://telemetry.smartgic.io/ovos-installer/dashboard-summary/"
    "?include_records=false"
)
OUTPUT_DIR = "docs/images"
TIMEOUT_SECONDS = 30

# One hue per chart. These are single-series charts, so colouring bars by their
# rank would attach meaning to position that the data does not have.
THEMES = {
    "light": {
        "surface": "none",
        "text_primary": "#0b0b0b",
        "text_secondary": "#52514e",
        "grid": "#d9d8d4",
        "os": "#2a78d6",
        "features": "#1baf7a",
    },
    "dark": {
        "surface": "none",
        "text_primary": "#f5f5f2",
        "text_secondary": "#a8a79f",
        "grid": "#3a3a38",
        "os": "#3987e5",
        "features": "#199e70",
    },
}

FONT = (
    "ui-sans-serif,-apple-system,BlinkMacSystemFont,'Segoe UI',"
    "Helvetica,Arial,sans-serif"
)

ROW_HEIGHT = 30
BAR_HEIGHT = 16
LABEL_WIDTH = 132
VALUE_WIDTH = 84
CHART_WIDTH = 720
TOP_PAD = 44
BOTTOM_PAD = 30


# The telemetry stores OS names as the installer detects them. Presentation is
# not data: the counts are untouched, only how the name is spelled on screen.
OS_DISPLAY_NAMES = {
    "archlinux": "Arch Linux",
    "cachyos": "CachyOS",
    "endeavouros": "EndeavourOS",
    "kde neon": "KDE neon",
    "linuxmint": "Linux Mint",
    "macosx": "macOS",
    "opensuse-leap": "openSUSE Leap",
    "opensuse-slowroll": "openSUSE Slowroll",
    "opensuse-tumbleweed": "openSUSE Tumbleweed",
    "pop": "Pop!_OS",
    "raspbian": "Raspberry Pi OS",
    "rhel": "RHEL",
    "wsl2": "WSL2",
    "zorin": "Zorin OS",
}


def display_name(raw):
    key = str(raw).strip().lower()
    if key in OS_DISPLAY_NAMES:
        return OS_DISPLAY_NAMES[key]
    return " ".join(word.capitalize() for word in key.split())


def escape(text):
    return (
        str(text)
        .replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def fetch_summary(offline):
    if offline:
        with open(offline, encoding="utf-8") as handle:
            return json.load(handle)

    request = urllib.request.Request(
        SUMMARY_URL, headers={"User-Agent": "ovos-installer-readme-charts"}
    )
    with urllib.request.urlopen(request, timeout=TIMEOUT_SECONDS) as response:
        return json.loads(response.read().decode("utf-8"))


def top_with_other(rows, limit):
    """The long tail of a distribution is noise on a README chart.

    Everything past the cut is summed into one honest "Other" rather than
    dropped, so the bars still add up to the whole population.
    """
    ordered = sorted(rows, key=lambda row: row["value"], reverse=True)
    head, tail = ordered[:limit], ordered[limit:]
    if tail:
        head.append({"name": "Other", "value": sum(row["value"] for row in tail)})
    return head


def bar_chart(title, subtitle, bars, colour_key, theme, value_format):
    """A horizontal bar chart: named categories compared by magnitude.

    Every bar carries its own value, which is also what relieves the light
    surface's contrast warning on the fill colour.
    """
    palette = THEMES[theme]
    height = TOP_PAD + ROW_HEIGHT * len(bars) + BOTTOM_PAD
    plot_width = CHART_WIDTH - LABEL_WIDTH - VALUE_WIDTH
    largest = max(bar["value"] for bar in bars) or 1

    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{CHART_WIDTH}" '
        f'height="{height}" viewBox="0 0 {CHART_WIDTH} {height}" '
        f'role="img" aria-label="{escape(title)}. {escape(subtitle)}">',
        f'<title>{escape(title)}</title>',
        f'<text x="0" y="18" font-family="{FONT}" font-size="15" '
        f'font-weight="600" fill="{palette["text_primary"]}">{escape(title)}</text>',
        f'<text x="0" y="36" font-family="{FONT}" font-size="12" '
        f'fill="{palette["text_secondary"]}">{escape(subtitle)}</text>',
    ]

    for index, bar in enumerate(bars):
        y = TOP_PAD + index * ROW_HEIGHT
        bar_y = y + (ROW_HEIGHT - BAR_HEIGHT) / 2
        width = max(2.0, plot_width * bar["value"] / largest)

        parts.append(
            f'<text x="{LABEL_WIDTH - 10}" y="{bar_y + BAR_HEIGHT - 3}" '
            f'text-anchor="end" font-family="{FONT}" font-size="12.5" '
            f'fill="{palette["text_primary"]}">{escape(bar["name"])}</text>'
        )
        parts.append(
            f'<rect x="{LABEL_WIDTH}" y="{bar_y}" width="{width:.1f}" '
            f'height="{BAR_HEIGHT}" rx="4" fill="{palette[colour_key]}"/>'
        )
        parts.append(
            f'<text x="{LABEL_WIDTH + width + 10:.1f}" '
            f'y="{bar_y + BAR_HEIGHT - 3}" font-family="{FONT}" font-size="12.5" '
            f'fill="{palette["text_secondary"]}">'
            f'{escape(value_format(bar))}</text>'
        )

    parts.append("</svg>")
    return "\n".join(parts) + "\n"


def write(path, content):
    previous = None
    if os.path.exists(path):
        with open(path, encoding="utf-8") as handle:
            previous = handle.read()

    if previous == content:
        print(f"unchanged {path}")
        return False

    with open(path, "w", encoding="utf-8") as handle:
        handle.write(content)
    print(f"wrote {path}")
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--offline", help="read the summary from a file instead of the network"
    )
    arguments = parser.parse_args()

    summary = fetch_summary(arguments.offline)
    aggregates = summary["aggregates"]
    total = summary["meta"]["record_count"]

    fetched = summary["meta"].get("fetched_at_utc", "")
    try:
        stamp = dt.datetime.fromisoformat(fetched).strftime("%d %b %Y")
    except (TypeError, ValueError):
        stamp = "unknown date"

    operating_systems = [
        {"name": display_name(row["name"]), "value": row["value"]}
        for row in top_with_other(aggregates["os"], 6)
    ]
    features = [
        {"name": row["label"], "value": row["percent"]}
        for row in aggregates["feature_adoption"]
    ]

    charts = [
        (
            "telemetry-os",
            "Where Open Voice OS is installed",
            f"{total:,} installs reported up to {stamp}",
            operating_systems,
            "os",
            lambda bar: f"{bar['value']:,} ({100 * bar['value'] / total:.0f}%)",
        ),
        (
            "telemetry-features",
            "What people turn on",
            f"Share of {total:,} installs enabling each feature",
            features,
            "features",
            lambda bar: f"{bar['value']:.0f}%",
        ),
    ]

    os.makedirs(OUTPUT_DIR, exist_ok=True)
    changed = False
    for name, title, subtitle, bars, colour, formatter in charts:
        for theme in THEMES:
            svg = bar_chart(title, subtitle, bars, colour, theme, formatter)
            path = os.path.join(OUTPUT_DIR, f"{name}-{theme}.svg")
            changed |= write(path, svg)

    print("changed" if changed else "no changes")
    return 0


if __name__ == "__main__":
    sys.exit(main())

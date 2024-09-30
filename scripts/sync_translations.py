import json
import os
from os.path import dirname

TEMPLATE = """
#!/bin/env bash

CONTENT="
{content}
"
TITLE="{title}"

export CONTENT TITLE

"""

MISC_TEMPLATE = """
#!/bin/env bash

OK_BUTTON="{ok_button}"
YES_BUTTON="{yes_button}"
NO_BUTTON="{no_button}"
BACK_BUTTON="{back_button}"

export OK_BUTTON YES_BUTTON NO_BUTTON BACK_BUTTON
"""

FEATURES_TEMPLATE = """
#!/bin/env bash

CONTENT="
{content}
"
TITLE="{title}"
SKILL_DESCRIPTION="{skill_description}"
EXTRA_SKILL_DESCRIPTION="{extra_skill_description}"
GUI_DESCRIPTION="{gui_description}"

export CONTENT TITLE SKILL_DESCRIPTION EXTRA_SKILL_DESCRIPTION GUI_DESCRIPTION
"""

SAT_TEMPLATE = """
#!/bin/env bash

# Global message
content="{content}"

# Host
CONTENT_HOST="
$content

{content_host}
"

# Port
CONTENT_PORT="
$content

{content_port}
"

# Key
CONTENT_KEY="
$content

{content_key}
"

# Password
CONTENT_PASSWORD="
$content

{content_password}
"

TITLE_HOST="{title_host}"
TITLE_PORT="{title_port}"
TITLE_KEY="{title_key}"
TITLE_PASSWORD="{title_password}"

export CONTENT_HOST CONTENT_PORT CONTENT_KEY CONTENT_PASSWORD TITLE_HOST TITLE_PORT TITLE_KEY TITLE_PASSWORD

"""

TEMPLATES = {
    "misc.sh": MISC_TEMPLATE,
    "channels.sh": TEMPLATE,
    "detection.sh": TEMPLATE,
    "features.sh": FEATURES_TEMPLATE,
    "finish.sh": TEMPLATE,
    "methods.sh": TEMPLATE,
    "profiles.sh": TEMPLATE,
    "satellite.sh": SAT_TEMPLATE,
    "summary.sh": TEMPLATE,
    "telemetry.sh": TEMPLATE,
    "tuning.sh": TEMPLATE,
    "uninstall.sh": TEMPLATE,
    "welcome.sh": TEMPLATE
}

TRANSLATIONS_FOLDER = f"{dirname(dirname(__file__))}/translations"
LOCALE_FOLDER = f"{dirname(dirname(__file__))}/tui/locales"


def load_lang_data(lang):
    with open(f"{TRANSLATIONS_FOLDER}/{lang}/strings.json") as f:
        data = json.load(f)
    return data


def update_locale(lang):
    data = load_lang_data(lang)
    for f, template in TEMPLATES.items():
        keys = {k.lower(): v for k, v in data[f].items()}
        os.makedirs(f"{LOCALE_FOLDER}/{lang}", exist_ok=True)
        with open(f"{LOCALE_FOLDER}/{lang}/{f}", "w") as f:
            f.write(template.format(**keys).strip())


for lang in os.listdir(TRANSLATIONS_FOLDER):
    update_locale(lang)


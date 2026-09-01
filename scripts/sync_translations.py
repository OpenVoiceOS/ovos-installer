import json
import os
from os.path import dirname

TEMPLATE = """
#!/usr/bin/env bash
CONTENT="
{content}
"
TITLE="{title}"

export CONTENT TITLE

"""

OVERCLOCK_TEMPLATE = """
#!/usr/bin/env bash
OVERCLOCK_CONTENT="
{content}
"
OVERCLOCK_TITLE="{title}"

export OVERCLOCK_CONTENT OVERCLOCK_TITLE
"""

MISC_TEMPLATE = """
#!/usr/bin/env bash
OK_BUTTON="{ok_button}"
YES_BUTTON="{yes_button}"
NO_BUTTON="{no_button}"
BACK_BUTTON="{back_button}"
QUIT_BUTTON="{quit_button}"
QUIT_TITLE="{quit_title}"
QUIT_CONTENT="{quit_content}"
NAV_HINT="{nav_hint}"

export OK_BUTTON YES_BUTTON NO_BUTTON BACK_BUTTON QUIT_BUTTON QUIT_TITLE QUIT_CONTENT NAV_HINT
"""

METHODS_TEMPLATE = """
#!/usr/bin/env bash
CONTENT="
{content}
"
LOCKED_CONTENT="
{locked_content}
"
TITLE="{title}"

export CONTENT LOCKED_CONTENT TITLE
"""

DETECTION_TEMPLATE = """
#!/usr/bin/env bash
CONTENT="
{content}
"
TITLE="{title}"

HARDWARE_CONFIRMATION_TITLE="{hardware_confirmation_title}"
HARDWARE_CONFIRMATION_MARK2_CONTENT="{hardware_confirmation_mark2_content}"
HARDWARE_CONFIRMATION_DEVKIT_CONTENT="{hardware_confirmation_devkit_content}"
HARDWARE_CONFIRMATION_GENERIC_NOTE="{hardware_confirmation_generic_note}"

export CONTENT TITLE HARDWARE_CONFIRMATION_TITLE HARDWARE_CONFIRMATION_MARK2_CONTENT HARDWARE_CONFIRMATION_DEVKIT_CONTENT HARDWARE_CONFIRMATION_GENERIC_NOTE
"""

SUMMARY_TEMPLATE = """
#!/usr/bin/env bash
CONTENT="
{content}
"
TITLE="{title}"

SUMMARY_STATE_ENABLED="{state_enabled}"
SUMMARY_STATE_DISABLED="{state_disabled}"
SUMMARY_STATE_UNSUPPORTED_PROFILE="{state_unsupported_profile}"
SUMMARY_STATE_MISSING_URL="{state_missing_url}"
SUMMARY_STATE_MISSING_CONFIGURATION="{state_missing_configuration}"

export CONTENT TITLE SUMMARY_STATE_ENABLED SUMMARY_STATE_DISABLED SUMMARY_STATE_UNSUPPORTED_PROFILE SUMMARY_STATE_MISSING_URL SUMMARY_STATE_MISSING_CONFIGURATION
"""

FEATURES_TEMPLATE = """
#!/usr/bin/env bash
CONTENT="
{content}
"
TITLE="{title}"
SKILL_DESCRIPTION="{skill_description}"
EXTRA_SKILL_DESCRIPTION="{extra_skill_description}"
GUI_DESCRIPTION="{gui_description}"
HOMEASSISTANT_DESCRIPTION="{homeassistant_description}"
LLM_DESCRIPTION="{llm_description}"

export CONTENT TITLE SKILL_DESCRIPTION EXTRA_SKILL_DESCRIPTION GUI_DESCRIPTION HOMEASSISTANT_DESCRIPTION LLM_DESCRIPTION
"""

SAT_TEMPLATE = """
#!/usr/bin/env bash
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
    "detection.sh": DETECTION_TEMPLATE,
    "features.sh": FEATURES_TEMPLATE,
    "finish.sh": TEMPLATE,
    "methods.sh": METHODS_TEMPLATE,
    "overclock.sh": OVERCLOCK_TEMPLATE,
    "profiles.sh": TEMPLATE,
    "satellite.sh": SAT_TEMPLATE,
    "summary.sh": SUMMARY_TEMPLATE,
    "telemetry.sh": TEMPLATE,
    "tuning.sh": TEMPLATE,
    "uninstall.sh": TEMPLATE,
    "update.sh": TEMPLATE,
    "usage_telemetry.sh": TEMPLATE,
    "welcome.sh": TEMPLATE
}

TRANSLATIONS_FOLDER = f"{dirname(dirname(__file__))}/translations"
LOCALE_FOLDER = f"{dirname(dirname(__file__))}/tui/locales"


def load_lang_data(lang):
    with open(f"{TRANSLATIONS_FOLDER}/{lang}/strings.json") as f:
        data = json.load(f)
    return data


EN_DATA = load_lang_data("en-us")


def update_locale(lang):
    data = load_lang_data(lang)
    for f, template in TEMPLATES.items():
        if f not in data:
            continue
        keys = {k.lower(): v for k, v in data[f].items()}
        # A locale lags behind en-us until a new string is translated. Fill the
        # gap with English instead of failing the whole sync on a KeyError.
        for key, value in EN_DATA.get(f, {}).items():
            keys.setdefault(key.lower(), value)
        os.makedirs(f"{LOCALE_FOLDER}/{lang}", exist_ok=True)
        with open(f"{LOCALE_FOLDER}/{lang}/{f}", "w") as f:
            f.write(template.format(**keys).strip()+"\n")


for lang in os.listdir(TRANSLATIONS_FOLDER):
    update_locale(lang)

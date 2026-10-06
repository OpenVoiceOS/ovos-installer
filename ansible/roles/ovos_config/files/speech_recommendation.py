"""Print the stt and tts sections ovos-config recommends for on-device speech.

Usage: speech_recommendation.py <locale> <male|female>

Reads the offline recommendations shipped with the ovos-config installed in
the OVOS virtualenv - the files `ovos-config autoconfigure --offline` merges -
so the plugins and models follow that release rather than a copy kept here.
Prints {"stt": {...} or null, "tts": {...} or null}; null means the release
has no recommendation for the locale.
"""
import json
import os
import sys

import ovos_config
from ovos_config.config import LocalConf

lang, gender = sys.argv[1], sys.argv[2]
root = os.path.join(os.path.dirname(ovos_config.__file__), "recommends")


def find(folder):
    path = os.path.join(root, folder)
    if not os.path.isdir(path):
        return None
    try:
        from ovos_config.utils import find_recommends_file
    except ImportError:
        # ovos-config 2.x: the exact tag, then a file sharing its primary subtag.
        exact = os.path.join(path, f"{lang.lower()}.conf")
        if os.path.isfile(exact):
            return exact
        primary = lang.lower().split("-")[0]
        for name in sorted(os.listdir(path)):
            if name.endswith(".conf") and name.lower().startswith(primary):
                return os.path.join(path, name)
        return None
    return find_recommends_file(path, lang)


def section(folder, key):
    path = find(folder)
    return LocalConf(path).get(key) if path else None


print(json.dumps({
    "stt": section("offline_stt", "stt"),
    "tts": section(f"offline_{gender}", "tts"),
}))

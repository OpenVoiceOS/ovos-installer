"""Load the configured local STT and TTS plugins once.

Usage: speech_prefetch.py <base64 of {"stt": {...}, "tts": {...}}> <locale>

Both plugins fetch their model when they are created, so doing it here moves
a download of up to a few gigabytes from the first utterance to the install.
"""
import base64
import json
import sys

from ovos_plugin_manager.stt import load_stt_plugin
from ovos_plugin_manager.tts import load_tts_plugin

sections, lang = json.loads(base64.b64decode(sys.argv[1])), sys.argv[2]

for kind, load in (("stt", load_stt_plugin), ("tts", load_tts_plugin)):
    section = sections.get(kind)
    if not section:
        continue
    module = section["module"]
    plugin = load(module)
    if plugin is None:
        sys.exit(f"{kind} plugin {module} is not installed")
    config = dict(section.get(module) or {})
    config.setdefault("lang", lang)
    plugin(config=config)
    print(f"{kind}: {module} ready")

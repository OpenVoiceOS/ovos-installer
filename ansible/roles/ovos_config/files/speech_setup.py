"""Pick, fetch and prove the on-device speech plugins for a locale.

Usage: speech_setup.py <stt|tts|stt,tts> <locale> <male|female> [STT memory budget in MB]

For each half asked for, it tries the configuration the installed ovos-config
recommends for the locale - the files `ovos-config autoconfigure --offline`
merges - and then the plugin's own choice for the language, and keeps the first
one that works on this machine: the recognizer has to load and run within the
memory budget, the voice has to actually speak. A recommendation alone is not
enough: one names a voice the installed phoonnx does not know, and another a
model that needs 5 GB of memory. Loading is also what downloads the model, so a
kept choice is ready for the first utterance.

Prints {"stt": section or null, "tts": section or null, "notes": [...]}. null
means nothing worked here, and that half stays on the public servers. A kept STT
section also carries the public servers ovos-config recommends for the locale,
for the fallback the installer adds to it.

The installer parses what this prints as JSON, and ovos_utils logs to stdout, so
stdout is pointed at stderr for the whole run and the result alone goes to the
real one.
"""
import json
import os
import re
import shutil
import subprocess
import sys

# Each candidate gets this long to download its model, load it and run once. That
# is far more than any of them needs - it is there so that a download that stalls
# without failing cannot hold the whole installation forever.
CANDIDATE_TIMEOUT = int(os.environ.get("OVOS_SPEECH_CANDIDATE_TIMEOUT", "1800"))

kinds, lang, gender = sys.argv[1].split(","), sys.argv[2], sys.argv[3]
budget_mb = int(sys.argv[4]) if len(sys.argv) > 4 else 3072
notes = []

# Each candidate is tried in a process of its own: a rejected 5 GB model then
# gives its memory back before the next one loads, instead of stacking up on an
# 8 GB board, and the peak this reports is that candidate's alone.
TRY = r'''
import json, os, resource, sys, tempfile
kind, lang, section = sys.argv[1], sys.argv[2], json.loads(sys.argv[3])
module = section["module"]
config = dict(section.get(module) or {}, lang=lang)
if kind == "stt":
    from ovos_plugin_manager.stt import load_stt_plugin
    from ovos_plugin_manager.utils.audio import AudioData
    plugin = load_stt_plugin(module)
    if plugin is None:
        sys.exit(f"{module} is not installed")
    plugin(config=config).execute(AudioData(b"\0\0" * 16000, 16000, 2), language=lang)
else:
    from ovos_plugin_manager.tts import load_tts_plugin
    plugin = load_tts_plugin(module)
    if plugin is None:
        sys.exit(f"{module} is not installed")
    with tempfile.TemporaryDirectory() as tmp:
        wav = os.path.join(tmp, "probe.wav")
        plugin(config=config).get_tts("Open Voice OS. 1, 2, 3.", wav)
        if os.path.getsize(wav) <= 44:
            sys.exit("the voice produced no audio")
peak = resource.getrusage(resource.RUSAGE_SELF).ru_maxrss
print(json.dumps({"peak_mb": peak // (1048576 if sys.platform == "darwin" else 1024)}))
'''


def find(folder):
    import ovos_config

    path = os.path.join(os.path.dirname(ovos_config.__file__), "recommends", folder)
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


def recommended(folder, key):
    from ovos_config.config import LocalConf

    path = find(folder)
    return LocalConf(path).get(key) if path else None


def prefer_int8(stt):
    """Ask for int8 weights where the model's repository ships them.

    A recommendation names a model, not its size: Spanish names a 1.1B model and
    no quantization, which loads 4.4 GB of fp32 weights next to an int8 copy of
    1.1 GB. Without the hub (offline, older images) the section is kept as is.
    """
    module = (stt or {}).get("module")
    options = dict((stt or {}).get(module) or {})
    model = options.get("model") or ""
    if "/" not in model or options.get("quantization"):
        return stt
    try:
        from huggingface_hub import HfApi
        files = HfApi().list_repo_files(model)
    except Exception:
        return stt
    if any(re.search(r"[._]int8\.onnx$", name) for name in files):
        options["quantization"] = "int8"
        stt = dict(stt, **{module: options})
    return stt


def stt_candidates():
    rec = recommended("offline_stt", "stt")
    if rec:
        yield "ovos-config's recommendation", prefer_int8(rec)
    try:
        from ovos_stt_plugin_onnxasr.defaults import resolve_model
        model = resolve_model(lang, {})
    except Exception:
        model = None
    if model:
        module = "ovos-stt-plugin-onnx-asr"
        yield "the plugin's own model for the language", prefer_int8(
            {"module": module, "fallback_module": "", module: {"model": model}})


def tts_candidates():
    rec = recommended(f"offline_{gender}", "tts")
    if rec:
        yield "ovos-config's recommendation", rec
    try:
        from phoonnx.model_manager import TTSModelManager
        manager = TTSModelManager()
        manager.load()
        manager.merge_default_voices()
        voices = [voice.voice_id for voice in manager.get_lang_voices(lang)]
    except Exception:
        voices = []
    module = "ovos-tts-plugin-phoonnx"
    # phoonnx lists a language's voices best first; a few tries are enough to
    # get past one that a phoonnx release cannot run.
    for voice in voices[:4]:
        yield "phoonnx's own voice for the language", {"module": module, module: {"voice": voice}}


def model_of(section):
    options = section.get(section["module"]) or {}
    return options.get("model") or options.get("voice") or section["module"]


def forget_model(model):
    """Delete a rejected recognizer model, so it does not hold the disk until uninstall."""
    try:
        from ovos_utils.xdg_utils import xdg_data_home
    except ImportError:
        return
    shutil.rmtree(os.path.join(xdg_data_home(), "ovos_stt_plugin_onnxasr", model.replace("/", "--")),
                  ignore_errors=True)


def first_working(kind, candidates):
    tried = set()
    for origin, section in candidates:
        model = model_of(section)
        if model in tried:
            continue
        tried.add(model)
        try:
            run = subprocess.run([sys.executable, "-c", TRY, kind, lang, json.dumps(section)],
                                 capture_output=True, text=True, timeout=CANDIDATE_TIMEOUT)
        except subprocess.TimeoutExpired:
            notes.append(f"{kind.upper()} {model} ({origin}) was given up on after "
                         f"{CANDIDATE_TIMEOUT} seconds")
            continue
        lines = [line for line in run.stdout.splitlines() if line.startswith("{")]
        if run.returncode != 0 or not lines:
            reason = (run.stderr.strip().splitlines() or ["it did not start"])[-1]
            notes.append(f"{kind.upper()} {model} ({origin}) does not work here: {reason[:200]}")
            continue
        peak = json.loads(lines[-1])["peak_mb"]
        if kind == "stt" and peak > budget_mb:
            notes.append(f"STT {model} ({origin}) needs {peak} MB, above the {budget_mb} MB budget")
            forget_model(model)
            continue
        if origin != "ovos-config's recommendation":
            notes.append(f"{kind.upper()} uses {model}, {origin}")
        return section
    return None


def with_public_fallback(stt):
    """Keep the locale's public STT servers in the section, for its fallback.

    The section replaces the whole of mycroft.conf's stt, and with it the servers
    `ovos-config autoconfigure --online` picked for the language - Spanish gets one
    with a Spanish model. Without them the fallback would use the plugin's default
    servers instead.
    """
    online = recommended("online_stt", "stt") or {}
    module = online.get("module")
    if stt is None or not module or not online.get(module):
        return stt
    return dict(stt, **{module: online[module]})


def set_up(kind, candidates):
    """first_working(), except that a fault in this script costs the half, not the run."""
    try:
        return first_working(kind, candidates())
    except Exception as error:
        notes.append(f"{kind.upper()} could not be set up: {type(error).__name__}: {error}")
        return None


result_stream = os.fdopen(os.dup(1), "w")
os.dup2(2, 1)

result = {"stt": None, "tts": None}
if "stt" in kinds:
    result["stt"] = set_up("stt", stt_candidates)
    try:
        result["stt"] = with_public_fallback(result["stt"])
    except Exception as error:
        notes.append(f"STT fallback keeps the default public servers: {error}")
if "tts" in kinds:
    result["tts"] = set_up("tts", tts_candidates)
result["notes"] = notes
result_stream.write(json.dumps(result) + "\n")
result_stream.flush()

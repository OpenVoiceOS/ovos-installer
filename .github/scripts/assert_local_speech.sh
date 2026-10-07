#!/usr/bin/env bash
# Assert that a local speech install really runs speech on the device.
#
# The configuration has to name the onnx-asr and phoonnx plugins, with the public
# server only as the STT fallback; the STT model has to be on disk already, because
# the installer fetches it rather than leaving it to the first utterance; and the
# pair has to work: the configured voice says a sentence and the configured
# recognizer hears it back. Nothing goes to the public servers on the way.
#
#   assert_local_speech.sh [venv-python]   a virtualenv install
#   assert_local_speech.sh --containers    a containers install: the voice speaks in
#                                          ovos_audio, the listener hears it in
#                                          ovos_listener, through the /tmp/mycroft
#                                          folder both of them mount
#
# Never run this under sudo. HOME decides which mycroft.conf is read and where the
# models were downloaded, and both belong to the install user.
set -euo pipefail

speak=$(
    cat <<'PY'
import sys
from ovos_config import Configuration
from ovos_plugin_manager.tts import load_tts_plugin

config = Configuration()
tts, lang = config["tts"], config["lang"]
if tts.get("module") != "ovos-tts-plugin-phoonnx":
    raise SystemExit(f"TTS is {tts.get('module')!r}, not the local phoonnx plugin")
voice = dict(tts.get(tts["module"]) or {}, lang=lang)
load_tts_plugin(tts["module"])(config=voice).get_tts("what time is it", sys.argv[1])
print(f"voice: {voice.get('voice')}")
PY
)

hear=$(
    cat <<'PY'
import os
import sys
from ovos_config import Configuration
from ovos_plugin_manager.stt import load_stt_plugin
from ovos_plugin_manager.utils.audio import AudioData

config = Configuration()
stt, lang = config["stt"], config["lang"]
if stt.get("module") != "ovos-stt-plugin-onnx-asr":
    raise SystemExit(f"STT is {stt.get('module')!r}, not the local onnx-asr plugin")
if stt.get("fallback_module") != "ovos-stt-plugin-server":
    raise SystemExit(f"STT fallback is {stt.get('fallback_module')!r}, not the public server")

models = os.path.expanduser("~/.local/share/ovos_stt_plugin_onnxasr")
if not os.path.isdir(models) or not os.listdir(models):
    raise SystemExit(f"no STT model in {models}: the install did not fetch it")

recognizer = dict(stt.get(stt["module"]) or {}, lang=lang)
heard = load_stt_plugin(stt["module"])(config=recognizer).execute(
    AudioData.from_file(sys.argv[1]), language=lang) or ""
if "time" not in heard.lower():
    raise SystemExit(f"the voice said 'what time is it' and the recognizer heard {heard!r}")
print(f"local speech ok: {recognizer.get('model')} heard {heard!r}")
PY
)

if [ "${1:-}" = "--containers" ]; then
    wav=/tmp/mycroft/local-speech.wav
    docker exec ovos_audio python3 -c "$speak" "$wav"
    docker exec ovos_listener python3 -c "$hear" "$wav"
    exit 0
fi

python_bin="${1:-${HOME}/.venvs/ovos/bin/python}"
if [ ! -x "${python_bin}" ]; then
    echo "no virtualenv python at ${python_bin}" >&2
    exit 1
fi

wav="$(mktemp --suffix=.wav)"
trap 'rm -f "$wav"' EXIT
"${python_bin}" -c "$speak" "$wav"
"${python_bin}" -c "$hear" "$wav"

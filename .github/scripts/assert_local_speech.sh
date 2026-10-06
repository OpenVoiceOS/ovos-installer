#!/usr/bin/env bash
# Assert that a local speech install really runs speech on the device.
#
# The configuration has to name the onnx-asr and phoonnx plugins, with the public
# server only as the STT fallback; the STT model has to be on disk already, because
# the installer fetches it rather than leaving it to the first utterance; and the
# pair has to work: the configured voice says a sentence and the configured
# recognizer hears it back. Nothing goes to the public servers on the way.
#
# Never run this under sudo. HOME decides which mycroft.conf is read and where the
# models were downloaded, and both belong to the install user.
set -euo pipefail

python_bin="${1:-${HOME}/.venvs/ovos/bin/python}"

if [ ! -x "${python_bin}" ]; then
    echo "no virtualenv python at ${python_bin}" >&2
    exit 1
fi

"${python_bin}" - <<'PY'
import os
import tempfile

from ovos_config import Configuration
from ovos_plugin_manager.stt import load_stt_plugin
from ovos_plugin_manager.tts import load_tts_plugin
from ovos_plugin_manager.utils.audio import AudioData

config = Configuration()
stt, tts, lang = config["stt"], config["tts"], config["lang"]

if stt.get("module") != "ovos-stt-plugin-onnx-asr":
    raise SystemExit(f"STT is {stt.get('module')!r}, not the local onnx-asr plugin")
if stt.get("fallback_module") != "ovos-stt-plugin-server":
    raise SystemExit(f"STT fallback is {stt.get('fallback_module')!r}, not the public server")
if tts.get("module") != "ovos-tts-plugin-phoonnx":
    raise SystemExit(f"TTS is {tts.get('module')!r}, not the local phoonnx plugin")

models = os.path.expanduser("~/.local/share/ovos_stt_plugin_onnxasr")
if not os.path.isdir(models) or not os.listdir(models):
    raise SystemExit(f"no STT model in {models}: the install did not fetch it")

stt_config = dict(stt.get(stt["module"]) or {}, lang=lang)
tts_config = dict(tts.get(tts["module"]) or {}, lang=lang)

wav = os.path.join(tempfile.mkdtemp(), "local-speech.wav")
load_tts_plugin(tts["module"])(config=tts_config).get_tts("what time is it", wav)
heard = load_stt_plugin(stt["module"])(config=stt_config).execute(
    AudioData.from_file(wav), language=lang) or ""

if "time" not in heard.lower():
    raise SystemExit(f"the voice said 'what time is it' and the recognizer heard {heard!r}")

print(f"local speech ok: {stt_config.get('model')} heard {heard!r} "
      f"from {tts_config.get('voice')}")
PY

#!/usr/bin/env bash
# Assert that a local speech install really runs speech on the device.
#
#   1. mycroft.conf names the onnx-asr and phoonnx plugins, with the public server
#      only as the STT fallback, and the STT model is on disk already: the installer
#      fetches it rather than leaving it to the first utterance;
#   2. the running listener loaded the onnx-asr recognizer - its own log says so;
#   3. the running audio service speaks with phoonnx (assert_local_speech_bus.py
#      asks it over the bus, and it names the plugin it used);
#   4. what that voice said, the running listener hears back. A listener with no
#      microphone never starts answering the bus, which is every CI runner, and then
#      the recognizer hears it in a fresh process instead.
#
# 1 alone was all this used to check, and it passes with services that never loaded
# what the file names - they only reload a mycroft.conf rewritten in place.
#
#   assert_local_speech.sh [venv-python]   a virtualenv install
#   assert_local_speech.sh --containers    a containers install (ovos_listener and
#                                          ovos_audio)
#
# Never run this under sudo. HOME decides which mycroft.conf is read and where the
# models and logs are, and all of them belong to the install user.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

stt_config=$(
    cat <<'PY'
import os
from ovos_config import Configuration

stt = Configuration()["stt"]
if stt.get("module") != "ovos-stt-plugin-onnx-asr":
    raise SystemExit(f"STT is {stt.get('module')!r}, not the local onnx-asr plugin")
if stt.get("fallback_module") != "ovos-stt-plugin-server":
    raise SystemExit(f"STT fallback is {stt.get('fallback_module')!r}, not the public server")
models = os.path.expanduser("~/.local/share/ovos_stt_plugin_onnxasr")
if not os.path.isdir(models) or not os.listdir(models):
    raise SystemExit(f"no STT model in {models}: the install did not fetch it")
print(f"config    : STT {(stt.get(stt['module']) or {}).get('model')}, public fallback")
PY
)

tts_config=$(
    cat <<'PY'
from ovos_config import Configuration

tts = Configuration()["tts"]
if tts.get("module") != "ovos-tts-plugin-phoonnx":
    raise SystemExit(f"TTS is {tts.get('module')!r}, not the local phoonnx plugin")
print(f"config    : TTS {(tts.get(tts['module']) or {}).get('voice')}")
PY
)

# What the voice said, heard in a process of its own. The path is "-" to read the
# audio from stdin, which is how it reaches a container.
hear=$(
    cat <<'PY'
import sys
import tempfile
from ovos_config import Configuration
from ovos_plugin_manager.stt import load_stt_plugin
from ovos_plugin_manager.utils.audio import AudioData

path = sys.argv[1]
if path == "-":
    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as wav:
        wav.write(sys.stdin.buffer.read())
    path = wav.name
config = Configuration()
stt, lang = config["stt"], config["lang"]
recognizer = dict(stt.get(stt["module"]) or {}, lang=lang)
heard = load_stt_plugin(stt["module"])(config=recognizer).execute(
    AudioData.from_file(path), language=lang) or ""
if "time" not in heard.lower():
    raise SystemExit(f"the voice said 'what time is it' and the recognizer heard {heard!r}")
print(f"recognizer: heard {heard!r} in a fresh process")
PY
)

wav="$(mktemp --suffix=.wav)"
websocket_dir=""
cleanup() {
    rm -f "$wav"
    if [ -n "$websocket_dir" ]; then
        rm -rf "$websocket_dir"
    fi
}
trap cleanup EXIT

if [ "${1:-}" = "--containers" ]; then
    docker exec ovos_listener python3 -c "$stt_config"
    docker exec ovos_audio python3 -c "$tts_config"
    listener_log() { docker logs ovos_listener 2>&1; }
    hear_fresh() { docker exec -i ovos_listener python3 -c "$hear" - <"$wav"; }
    # No host venv: the bus check needs websocket-client and nothing else, so it goes
    # into a throwaway directory rather than ~/.local (see assert_intent_roundtrip.sh).
    bus_python=python3
    if ! python3 -c "import websocket" 2>/dev/null; then
        websocket_dir="$(mktemp -d)"
        python3 -m pip install --quiet --disable-pip-version-check --no-cache-dir \
            --target "$websocket_dir" websocket-client
        export PYTHONPATH="${websocket_dir}${PYTHONPATH:+:${PYTHONPATH}}"
    fi
else
    venv_python="${1:-${HOME}/.venvs/ovos/bin/python}"
    if [ ! -x "${venv_python}" ]; then
        echo "no virtualenv python at ${venv_python}" >&2
        exit 1
    fi
    "${venv_python}" -c "$stt_config"
    "${venv_python}" -c "$tts_config"
    listener_log() { cat "${XDG_STATE_HOME:-${HOME}/.local/state}/mycroft/voice.log"; }
    hear_fresh() { "${venv_python}" -c "$hear" "$wav"; }
    bus_python="${venv_python}"
fi

# The plugin logs as it loads its model, and every line names its module. Not grep
# -q: it stops reading at the first match, the log writer dies of SIGPIPE, and
# pipefail turns a found line into a failure.
if ! listener_log | grep -F "ovos_stt_plugin_onnxasr" >/dev/null; then
    echo "the running listener never loaded the onnx-asr recognizer" >&2
    exit 1
fi
echo "listener  : loaded the onnx-asr recognizer"

status=0
"${bus_python}" "${here}/assert_local_speech_bus.py" --wav "$wav" || status=$?
case "$status" in
0) ;;
3) hear_fresh ;;
*) exit "$status" ;;
esac

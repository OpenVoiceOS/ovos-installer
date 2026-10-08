"""The local speech check that asks the running services, against a fake messagebus.

.github/scripts/assert_local_speech_bus.py is what tells a local speech install whose
services really loaded the local plugins from one whose mycroft.conf merely names them.
Each way that can go wrong is played here by a bus that answers in that one wrong way.
"""
import io
import subprocess
import sys
import tempfile
import time
import unittest
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HARNESS = ROOT / ".github" / "scripts" / "assert_local_speech_bus.py"

try:
    import websockets  # noqa: F401  (used by the subprocess server below)
    HAVE_SERVER = True
except ImportError:
    HAVE_SERVER = False

try:
    import websocket  # noqa: F401
    HAVE_CLIENT = True
except ImportError:
    HAVE_CLIENT = False

SERVER = r"""
import asyncio, base64, io, json, sys, wave, websockets
MODE, PORT = sys.argv[1], int(sys.argv[2])

def voice():
    # What phoonnx produces: a mono 16-bit WAV at 22050 Hz.
    out = io.BytesIO()
    with wave.open(out, "wb") as wav:
        wav.setnchannels(1)
        wav.setsampwidth(2)
        wav.setframerate(22050)
        wav.writeframes(b"\x01\x00" * 2205)
    return out.getvalue()

async def handler(ws):
    async for raw in ws:
        m = json.loads(raw)
        kind, data, ctx = m.get("type"), m.get("data") or {}, m.get("context") or {}
        async def send(rt, payload, context=ctx):
            await ws.send(json.dumps({"type": rt, "data": payload, "context": context}))
        if kind.endswith(".is_ready"):
            if kind == "mycroft.voice.is_ready" and MODE == "no_microphone":
                continue
            await send(kind + ".response", {"status": True})
        elif kind == "speak:b64_audio":
            tts_id = "ovos-tts-plugin-server" if MODE == "never_reloaded" else "ovos-tts-plugin-phoonnx"
            payload = {"audio": base64.b64encode(voice()).decode(), "listen": False,
                       "tts_id": tts_id, "utterance": data.get("utterance")}
            # Someone else's speech first: it must not be taken for the answer.
            await send("ovos.audio.speech", dict(payload, tts_id="other"), {"source": ["skills"]})
            topic = "speak:b64_audio.response" if MODE == "legacy_audio" else "ovos.audio.speech"
            await send(topic, payload)
        elif kind == "recognizer_loop:b64_transcribe":
            audio = base64.b64decode(data.get("audio", ""))
            # The listener reads raw frames at the rate it is told. A WAV header, or the
            # wrong rate, is noise to it.
            if audio.startswith(b"RIFF") or data.get("sample_rate") != 22050 or data.get("sample_width") != 2:
                heard = "brr"
            else:
                heard = "" if MODE == "deaf_listener" else "what time is it"
            await send("recognizer_loop:b64_transcribe.response",
                       {"transcriptions": [[heard, 0.9]], "lang": "en-US"})

async def main():
    async with websockets.serve(handler, "127.0.0.1", PORT):
        print("ready", flush=True)
        await asyncio.Future()

asyncio.run(main())
"""


class FakeBus:
    """A messagebus whose audio service and listener answer correctly, or in one wrong way."""

    _next_port = [8371]

    def __init__(self, mode="healthy"):
        self.mode = mode
        self.port = FakeBus._next_port[0]
        FakeBus._next_port[0] += 1
        self.proc = None

    def __enter__(self):
        self.proc = subprocess.Popen(
            [sys.executable, "-c", SERVER, self.mode, str(self.port)],
            stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        deadline = time.monotonic() + 15
        while time.monotonic() < deadline:
            line = self.proc.stdout.readline()
            if line.strip() == "ready":
                return self
            if self.proc.poll() is not None:
                raise RuntimeError(f"fake bus died: {self.proc.stderr.read()}")
        raise RuntimeError("fake bus never became ready")

    def __exit__(self, *exc):
        if self.proc and self.proc.poll() is None:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.proc.kill()
                self.proc.wait()
        if self.proc:
            self.proc.stdout.close()
            self.proc.stderr.close()


@unittest.skipUnless(HAVE_SERVER and HAVE_CLIENT,
                     "needs websockets (server) and websocket-client (harness)")
class RunningServicesCheck(unittest.TestCase):

    def check(self, mode):
        with FakeBus(mode) as bus, tempfile.TemporaryDirectory() as tmp:
            wav = Path(tmp) / "said.wav"
            result = subprocess.run(
                [sys.executable, str(HARNESS), "--url", f"ws://127.0.0.1:{bus.port}/core",
                 "--wav", str(wav), "--connect-timeout", "4", "--ready-timeout", "6",
                 "--listener-ready-timeout", "3", "--reply-timeout", "4"],
                capture_output=True, text=True, timeout=90)
            written = wav.read_bytes() if wav.exists() else b""
        return result.returncode, result.stdout + result.stderr, written

    def test_services_that_speak_and_hear_locally_pass(self):
        code, output, _ = self.check("healthy")
        self.assertEqual(code, 0, output)
        self.assertIn("ovos-tts-plugin-phoonnx", output)
        self.assertIn("heard 'what time is it'", output)

    def test_an_answer_on_the_legacy_topic_counts(self):
        code, output, _ = self.check("legacy_audio")
        self.assertEqual(code, 0, output)

    def test_an_audio_service_still_on_the_public_voice_fails(self):
        # mycroft.conf names phoonnx, the service never reloaded it: the case that every
        # check on the file passes.
        code, output, _ = self.check("never_reloaded")
        self.assertEqual(code, 1, output)
        self.assertIn("ovos-tts-plugin-server", output)
        self.assertIn("never loaded it", output)

    def test_a_listener_with_no_microphone_hands_the_audio_back(self):
        # Exit 3 is the caller's cue to have the recognizer hear the file in a process of
        # its own, so the file has to be the voice's own WAV.
        code, output, written = self.check("no_microphone")
        self.assertEqual(code, 3, output)
        with wave.open(io.BytesIO(written)) as wav:
            self.assertEqual(wav.getframerate(), 22050)

    def test_a_listener_that_hears_nothing_fails(self):
        code, output, _ = self.check("deaf_listener")
        self.assertEqual(code, 1, output)
        self.assertIn("heard ''", output)

    def test_it_is_executable_and_documents_its_own_flags(self):
        self.assertTrue(HARNESS.stat().st_mode & 0o111, "the harness must be executable")
        result = subprocess.run([sys.executable, str(HARNESS), "--help"],
                                capture_output=True, text=True, timeout=30)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("--expect-tts", result.stdout)


if __name__ == "__main__":
    unittest.main()

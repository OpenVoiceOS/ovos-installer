"""What the local speech setup keeps, and what it refuses.

ovos_config/files/speech_setup.py runs inside the OVOS virtualenv, or the listener and
audio containers, and decides what the device will use for speech. It is driven here
against stand-ins for ovos-config (both the 2.x and the 3.x way of finding a language),
the Hugging Face hub, the plugin manager and the two plugins' own per-language choices,
so each fallback can be made to happen on purpose. The candidates are still tried in real
child processes, which is where the memory budget is measured.
"""
import json
import os
import subprocess
import sys
import tempfile
import textwrap
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SETUP = ROOT / "ansible" / "roles" / "ovos_config" / "files" / "speech_setup.py"
STT = "ovos-stt-plugin-onnx-asr"
TTS = "ovos-tts-plugin-phoonnx"

STUBS = {
    # ovos_utils logs to stdout; STUB_NOISY makes the stand-in do the same, at the
    # Python and at the file descriptor level, the way an import really can.
    "ovos_config/config.py": """
        import json, os, sys

        if os.environ.get("STUB_NOISY"):
            print("2026-10-07 - OVOS - ovos_config:load:1 - INFO - loading configuration")
            sys.stdout.flush()
            os.write(1, b"raw write from an extension\\n")


        class LocalConf(dict):
            def __init__(self, path):
                super().__init__(json.load(open(path)))
    """,
    "ovos_plugin_manager/__init__.py": "",
    "ovos_plugin_manager/utils/__init__.py": "",
    "ovos_plugin_manager/utils/audio.py": """
        class AudioData:
            def __init__(self, frames, rate, width):
                self.frames = frames
    """,
    # Loading downloads the model where the plugin keeps it, as the real one does. A
    # model whose name starts with "broken" then fails to load, one starting with
    # "huge" holds 200 MB once loaded, one starting with "stalled" never finishes
    # loading; anything else loads and hears nothing.
    "ovos_plugin_manager/stt.py": """
        import os, time


        class Recognizer:
            def __init__(self, config):
                model = config.get("model", "")
                cache = os.path.join(os.environ["STUB_XDG_DATA_HOME"], "ovos_stt_plugin_onnxasr",
                                     model.replace("/", "--"))
                os.makedirs(cache, exist_ok=True)
                open(os.path.join(cache, "model.onnx"), "a").close()
                if model.startswith("broken"):
                    raise RuntimeError("cannot load " + model)
                if model.startswith("stalled"):
                    time.sleep(60)
                self.weights = b"x" * (200 * 1024 * 1024) if model.startswith("huge") else b""

            def execute(self, audio, language=None):
                return ""


        def load_stt_plugin(module):
            return Recognizer if module == "ovos-stt-plugin-onnx-asr" else None
    """,
    # A voice whose name starts with "mute" loads but cannot speak, like the Spanish
    # voices in phoonnx 1.3.4a1.
    "ovos_plugin_manager/tts.py": """
        import wave


        class Voice:
            def __init__(self, config):
                self.voice = config.get("voice", "")

            def get_tts(self, text, path):
                if self.voice.startswith("mute"):
                    raise wave.Error("# channels not specified")
                with wave.open(path, "wb") as out:
                    out.setnchannels(1)
                    out.setsampwidth(2)
                    out.setframerate(16000)
                    out.writeframes(b"\\0\\0" * 1600)


        def load_tts_plugin(module):
            return Voice if module == "ovos-tts-plugin-phoonnx" else None
    """,
    "ovos_stt_plugin_onnxasr/__init__.py": "",
    "ovos_stt_plugin_onnxasr/defaults.py": """
        import json, os

        REGISTRY = json.loads(os.environ.get("STUB_STT_REGISTRY", "{}"))


        def resolve_model(lang, lang2model):
            return REGISTRY.get(lang.lower().split("-")[0])
    """,
    "phoonnx/__init__.py": "",
    "phoonnx/model_manager.py": """
        import json, os

        VOICES = json.loads(os.environ.get("STUB_VOICES", "{}"))


        class Voice:
            def __init__(self, voice_id):
                self.voice_id = voice_id


        class TTSModelManager:
            def load(self):
                pass

            def merge_default_voices(self):
                pass

            def get_lang_voices(self, lang):
                return [Voice(v) for v in VOICES.get(lang.lower().split("-")[0], [])]
    """,
    "ovos_utils/__init__.py": "",
    "ovos_utils/xdg_utils.py": """
        import os


        def xdg_data_home():
            return os.environ["STUB_XDG_DATA_HOME"]
    """,
    "huggingface_hub/__init__.py": """
        import json, os


        class HfApi:
            def list_repo_files(self, repo):
                return json.loads(os.environ.get("STUB_HUB", "{}")).get(repo, [])
    """,
}


def stt(model, **options):
    return {"stt": {"module": STT, "fallback_module": "", STT: dict(model=model, **options)}}


def tts(voice):
    return {"tts": {"module": TTS, TTS: {"voice": voice}}}


class SpeechSetupTest(unittest.TestCase):

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.root = Path(self.tmp.name)
        self.data = self.root / "data"
        self.data.mkdir()
        for path, content in STUBS.items():
            target = self.root / "stubs" / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(textwrap.dedent(content))
        self.env = dict(os.environ, PYTHONPATH=str(self.root / "stubs"), STUB_XDG_DATA_HOME=str(self.data))

    def tearDown(self):
        self.tmp.cleanup()

    def recommends(self, files, find_by_distance=False):
        package = self.root / "stubs" / "ovos_config"
        (package / "__init__.py").write_text("")
        if find_by_distance:
            (package / "utils.py").write_text(textwrap.dedent("""
                import os


                def find_recommends_file(folder, lang):
                    primary = lang.lower().split("-")[0]
                    for name in sorted(os.listdir(folder)):
                        if name.lower().startswith(primary):
                            return os.path.join(folder, name)
                    return None
            """))
        for path, content in files.items():
            target = package / "recommends" / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(json.dumps(content))

    def setup(self, lang, kinds="stt,tts", gender="male", budget=100, registry=None, voices=None, hub=None,
              **env_extra):
        env = dict(self.env, STUB_STT_REGISTRY=json.dumps(registry or {}),
                   STUB_VOICES=json.dumps(voices or {}), STUB_HUB=json.dumps(hub or {}), **env_extra)
        out = subprocess.run([sys.executable, str(SETUP), kinds, lang, gender, str(budget)],
                             capture_output=True, text=True, env=env, check=True).stdout
        # The installer parses the whole of stdout, so nothing else may be on it.
        return json.loads(out)

    def test_working_recommendations_are_kept_as_they_are(self):
        self.recommends({"offline_stt/en-us.conf": stt("parakeet", quantization="int8"),
                         "offline_male/en-us.conf": tts("OpenVoiceOS/pipertts_en-US_miro")})
        result = self.setup("en-us")
        self.assertEqual(result["stt"][STT], {"model": "parakeet", "quantization": "int8"})
        self.assertEqual(result["tts"][TTS]["voice"], "OpenVoiceOS/pipertts_en-US_miro")
        self.assertEqual(result["notes"], [])

    def test_2x_finds_a_language_by_its_primary_subtag(self):
        self.recommends({"offline_male/da-dk.conf": tts("OpenVoiceOS/phoonnx_da-DK_miro_espeak")})
        self.assertEqual(self.setup("da", kinds="tts")["tts"][TTS]["voice"], "OpenVoiceOS/phoonnx_da-DK_miro_espeak")

    def test_3x_asks_ovos_config_for_the_closest_tag(self):
        self.recommends({"offline_stt/kab.conf": stt("OpenVoiceOS/nvidia-kab-conformer")}, find_by_distance=True)
        self.assertEqual(self.setup("kab-dz", kinds="stt")["stt"][STT]["model"], "OpenVoiceOS/nvidia-kab-conformer")

    def test_a_recognizer_that_does_not_load_gives_way_to_the_plugins_own_model(self):
        self.recommends({"offline_stt/ca-es.conf": stt("broken/ca-model")})
        result = self.setup("ca-es", kinds="stt", registry={"ca": "OpenVoiceOS/nvidia-ca-conformer"})
        self.assertEqual(result["stt"][STT]["model"], "OpenVoiceOS/nvidia-ca-conformer")
        self.assertTrue(any("broken/ca-model" in note for note in result["notes"]))

    def test_a_recognizer_over_the_memory_budget_gives_way_and_is_deleted(self):
        self.recommends({"offline_stt/pt-pt.conf": stt("huge/whisper-medium-pt")})
        downloaded = self.data / "ovos_stt_plugin_onnxasr" / "huge--whisper-medium-pt"
        result = self.setup("pt-pt", kinds="stt", budget=100, registry={"pt": "OpenVoiceOS/parakeet-pt"})
        self.assertEqual(result["stt"][STT]["model"], "OpenVoiceOS/parakeet-pt")
        self.assertTrue(any("above the 100 MB budget" in note for note in result["notes"]))
        self.assertFalse(downloaded.exists())

    def test_a_recognizer_over_the_budget_that_was_there_before_is_kept(self):
        # An earlier install's local section can name the very model tried here.
        self.recommends({"offline_stt/pt-pt.conf": stt("huge/whisper-medium-pt")})
        earlier = self.data / "ovos_stt_plugin_onnxasr" / "huge--whisper-medium-pt"
        earlier.mkdir(parents=True)
        (earlier / "weights.onnx").write_text("an earlier download")
        result = self.setup("pt-pt", kinds="stt", budget=100, registry={"pt": "OpenVoiceOS/parakeet-pt"})
        self.assertEqual(result["stt"][STT]["model"], "OpenVoiceOS/parakeet-pt")
        self.assertEqual((earlier / "weights.onnx").read_text(), "an earlier download")

    def test_a_voice_that_cannot_speak_gives_way_to_the_next_phoonnx_voice(self):
        self.recommends({"offline_male/es-es.conf": tts("mute/pipertts_es-ES_miro")})
        result = self.setup("es-es", kinds="tts", voices={"es": ["mute/pipertts_es-ES_miro", "piper/es_ES-davefx-medium"]})
        self.assertEqual(result["tts"][TTS]["voice"], "piper/es_ES-davefx-medium")

    def test_a_language_without_a_recommendation_uses_the_plugins_own_choice(self):
        self.recommends({})
        result = self.setup("pl-pl", registry={"pl": "OpenVoiceOS/parakeet-pl"}, voices={"pl": ["piper/pl_PL-gosia-medium"]})
        self.assertEqual(result["stt"][STT]["model"], "OpenVoiceOS/parakeet-pl")
        self.assertEqual(result["stt"]["fallback_module"], "")
        self.assertEqual(result["tts"][TTS]["voice"], "piper/pl_PL-gosia-medium")

    def test_when_nothing_works_both_halves_stay_public(self):
        self.recommends({"offline_stt/es-es.conf": stt("broken/es"), "offline_male/es-es.conf": tts("mute/es")})
        result = self.setup("es-es", voices={"es": ["mute/es", "mute/other"]})
        self.assertIsNone(result["stt"])
        self.assertIsNone(result["tts"])

    def test_int8_is_asked_for_where_the_repository_ships_it(self):
        model = "OpenVoiceOS/parakeet-rnnt-1.1b-es"
        self.recommends({"offline_stt/es-es.conf": stt(model)})
        result = self.setup("es-es", kinds="stt", hub={model: ["encoder-model.onnx_data", "encoder-model.int8.onnx"]})
        self.assertEqual(result["stt"][STT]["quantization"], "int8")

    def test_a_repository_without_int8_weights_is_left_alone(self):
        model = "OpenVoiceOS/whisper-medium-pt"
        self.recommends({"offline_stt/pt-pt.conf": stt(model)})
        result = self.setup("pt-pt", kinds="stt", hub={model: ["encoder_model.onnx_data"]})
        self.assertNotIn("quantization", result["stt"][STT])

    def test_only_the_result_reaches_stdout(self):
        # ovos_utils logs to stdout, and an import that logs or writes would put a line
        # in front of the JSON the installer parses - the whole install would stop on it.
        self.recommends({"offline_stt/en-us.conf": stt("parakeet"), "offline_male/en-us.conf": tts("miro")})
        result = self.setup("en-us", STUB_NOISY="1")
        self.assertIsNotNone(result["stt"])
        self.assertIsNotNone(result["tts"])

    def test_the_fallback_keeps_the_public_servers_ovos_config_picks_for_the_locale(self):
        # The local section replaces the whole stt section, and with it the servers
        # autoconfigure --online chose for the language; the fallback needs them back.
        servers = {"urls": ["https://zuazo-es.tigregotico.pt/stt", "https://stt.smartgic.io/fasterwhisper/stt"]}
        self.recommends({"offline_stt/es-es.conf": stt("parakeet-es"),
                         "online_stt/es-es.conf": {"stt": {"module": "ovos-stt-plugin-server",
                                                           "ovos-stt-plugin-server": servers}}})
        result = self.setup("es-es", kinds="stt")
        self.assertEqual(result["stt"][STT]["model"], "parakeet-es")
        self.assertEqual(result["stt"]["ovos-stt-plugin-server"], servers)

    def test_without_public_servers_for_the_locale_the_fallback_keeps_its_defaults(self):
        self.recommends({"offline_stt/kab-dz.conf": stt("kab-conformer")})
        result = self.setup("kab-dz", kinds="stt")
        self.assertNotIn("ovos-stt-plugin-server", result["stt"])

    def test_a_fault_while_choosing_costs_that_half_and_not_the_run(self):
        # A recommendation that is not even JSON: the script must still answer, with the
        # other half set up and the reason in the notes, rather than exit without a result.
        self.recommends({"offline_male/en-us.conf": tts("miro")})
        broken = self.root / "stubs" / "ovos_config" / "recommends" / "offline_stt" / "en-us.conf"
        broken.parent.mkdir(parents=True, exist_ok=True)
        broken.write_text("{ not json")
        result = self.setup("en-us")
        self.assertIsNone(result["stt"])
        self.assertEqual(result["tts"][TTS]["voice"], "miro")
        self.assertTrue(any(note.startswith("STT could not be set up") for note in result["notes"]))

    def test_a_candidate_that_never_finishes_is_given_up_on(self):
        self.recommends({"offline_stt/en-us.conf": stt("stalled/parakeet")})
        result = self.setup("en-us", kinds="stt", registry={"en": "OpenVoiceOS/parakeet-en"},
                            OVOS_SPEECH_CANDIDATE_TIMEOUT="3")
        self.assertEqual(result["stt"][STT]["model"], "OpenVoiceOS/parakeet-en")
        self.assertTrue(any("stalled/parakeet" in note and "given up on" in note for note in result["notes"]))

    def test_only_the_halves_asked_for_are_set_up(self):
        self.recommends({"offline_stt/en-us.conf": stt("parakeet"), "offline_male/en-us.conf": tts("miro")})
        result = self.setup("en-us", kinds="stt")
        self.assertIsNotNone(result["stt"])
        self.assertIsNone(result["tts"])


if __name__ == "__main__":
    unittest.main()

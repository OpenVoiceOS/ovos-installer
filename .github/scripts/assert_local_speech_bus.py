#!/usr/bin/env python3
"""Have the running services speak and listen, over the messagebus.

assert_local_speech.sh checks mycroft.conf and the plugins it names. That is not the
same as the services using them: they load their plugins when they start and reload
only a configuration file rewritten in place, so a mycroft.conf they never picked up
passes every check made on the file while the device keeps talking to the public
servers. This asks the services themselves:

  1. the audio service synthesises a sentence for the bus (speak:b64_audio) and names
     the plugin that did it, which must be the local one;
  2. the listener transcribes that audio with its own recognizer
     (recognizer_loop:b64_transcribe), never its fallback, and must hear the sentence.

The listener only starts answering the bus once its microphone has started, and a CI
runner has no microphone. When it never reports ready, the audio is still written to
--wav and this exits 3, so the caller can have the recognizer hear it in a fresh
process instead.

Like assert_intent_roundtrip.py, which this borrows its bus client from, it speaks the
bus protocol over a bare websocket, so it runs the same on a host with no venv.
"""
import argparse
import base64
import io
import secrets
import sys
import time
import wave

from assert_intent_roundtrip import Bus, Failure, wait_ready

LISTENER_UNAVAILABLE = 3
LOCAL_TTS = "ovos-tts-plugin-phoonnx"


def speak(bus, utterance, timeout):
    """The audio service's own TTS, as bytes of a WAV file, and the plugin it used."""
    marker = secrets.token_hex(8)
    bus.send("speak:b64_audio", {"utterance": utterance},
             {"source": ["ci"], "ci_probe": marker})
    # Newer services answer on the spec topic, older ones on the legacy one, and the
    # bus client may mirror one onto the other: whichever comes first will do.
    answer = bus.wait_for(("ovos.audio.speech", "speak:b64_audio.response"), timeout,
                          match=lambda m: (m.get("context") or {}).get("ci_probe") == marker)
    if answer is None:
        raise Failure(
            f"the audio service did not synthesise {utterance!r} for the bus within "
            f"{timeout:.0f}s, having reported itself ready."
        )
    data = answer.get("data") or {}
    try:
        return base64.b64decode(data["audio"]), data.get("tts_id")
    except (KeyError, TypeError, ValueError) as error:
        raise Failure(f"the audio service answered without usable audio: {error!r}")


def pcm(wav_bytes):
    """The frames of a mono WAV, with the rate and width the listener needs to read them."""
    try:
        with wave.open(io.BytesIO(wav_bytes)) as wav:
            if wav.getnchannels() != 1:
                raise Failure(f"the voice produced {wav.getnchannels()} channels, not one")
            return wav.readframes(wav.getnframes()), wav.getframerate(), wav.getsampwidth()
    except (wave.Error, EOFError) as error:
        raise Failure(f"the audio service's answer is not a WAV file: {error}")


def transcribe(bus, wav_bytes, timeout):
    frames, rate, width = pcm(wav_bytes)
    marker = secrets.token_hex(8)
    bus.send("recognizer_loop:b64_transcribe",
             {"audio": base64.b64encode(frames).decode("ascii"),
              "sample_rate": rate, "sample_width": width},
             {"source": ["ci"], "ci_probe": marker})
    answer = bus.wait_for("recognizer_loop:b64_transcribe.response", timeout,
                          match=lambda m: (m.get("context") or {}).get("ci_probe") == marker)
    if answer is None:
        raise Failure(
            f"the listener did not transcribe the audio within {timeout:.0f}s, having "
            f"reported itself ready."
        )
    heard = []
    for transcription in (answer.get("data") or {}).get("transcriptions") or []:
        # (text, confidence) pairs, which JSON turns into lists; plain strings from
        # older listeners.
        heard.append(transcription[0] if isinstance(transcription, (list, tuple))
                     else str(transcription))
    return heard[0] if heard else ""


def main(argv=None):
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--url", default="ws://127.0.0.1:8181/core")
    parser.add_argument("--utterance", default="what time is it")
    parser.add_argument("--expect-word", default="time",
                        help="a word the recognizer has to hear in --utterance")
    parser.add_argument("--expect-tts", default=LOCAL_TTS,
                        help="the plugin the audio service has to name")
    parser.add_argument("--wav", required=True,
                        help="where to write what the voice said")
    parser.add_argument("--connect-timeout", type=float, default=30)
    parser.add_argument("--ready-timeout", type=float, default=300,
                        help="the services restart onto local speech, and the "
                             "listener loads its model before it answers")
    parser.add_argument("--listener-ready-timeout", type=float, default=60,
                        help="how long to give a listener that may have no "
                             "microphone to start with")
    parser.add_argument("--reply-timeout", type=float, default=120)
    args = parser.parse_args(argv)

    bus = None
    try:
        bus = Bus(args.url, args.connect_timeout)
        wait_ready(bus, "audio", args.ready_timeout)

        started = time.monotonic()
        wav_bytes, tts_id = speak(bus, args.utterance, args.reply_timeout)
        print(f"voice     : the audio service said {args.utterance!r} with {tts_id} "
              f"in {time.monotonic() - started:.1f}s")
        with open(args.wav, "wb") as out:
            out.write(wav_bytes)
        if tts_id != args.expect_tts:
            raise Failure(
                f"the running audio service speaks with {tts_id!r}, not {args.expect_tts!r}. "
                f"mycroft.conf may name the local voice, but the service never loaded it."
            )

        try:
            wait_ready(bus, "voice", args.listener_ready_timeout)
        except Failure:
            print("listener  : not ready, so it is not answering the bus here (no "
                  "microphone to start with?)")
            return LISTENER_UNAVAILABLE

        started = time.monotonic()
        heard = transcribe(bus, wav_bytes, args.reply_timeout)
        print(f"listener  : heard {heard!r} in {time.monotonic() - started:.1f}s")
        if args.expect_word not in heard.lower():
            raise Failure(
                f"the voice said {args.utterance!r} and the running listener heard "
                f"{heard!r}."
            )
        print("the running services speak and hear on this device")
        return 0
    except Failure as failure:
        print(f"\nlocal speech check failed: {failure}", file=sys.stderr)
        return 1
    finally:
        if bus is not None:
            bus.close()


if __name__ == "__main__":
    sys.exit(main())

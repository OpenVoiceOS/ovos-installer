"""What the intent round trip refuses to call success.

The value of this check is entirely in the rungs it will not skip, so each rung is driven
against a stand-in messagebus that misbehaves in one specific way. A check that cannot
fail is the shape this repository has spent a lot of effort removing; these tests exist so
that this one cannot quietly become it.

The stand-in is a real websocket server speaking the real bus protocol, because the
transport is half of what the harness does. Where websockets or websocket-client are
absent the socket tests skip, and the argument handling is still covered - so read a skip
here as reduced coverage, not as a pass.
"""
import os
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
HARNESS = ROOT / ".github" / "scripts" / "assert_intent_roundtrip.py"

try:
    import websockets  # noqa: F401  (used by the subprocess server above)
    HAVE_SERVER = True
except ImportError:
    HAVE_SERVER = False

try:
    import websocket  # noqa: F401
    HAVE_CLIENT = True
except ImportError:
    HAVE_CLIENT = False

SERVER = r"""
import asyncio, json, sys, websockets
MODE, PORT = sys.argv[1], int(sys.argv[2])
MATCH = {"intent_name": "stop:global",
         "intent_service": "ovos-stop-pipeline-plugin-high",
         "skill_id": "stop.openvoiceos"}

DROPPED = [0]

async def handler(ws):
    async for raw in ws:
        m = json.loads(raw)
        kind, data = m.get("type"), m.get("data") or {}
        async def reply(rt, payload):
            await ws.send(json.dumps({"type": rt, "data": payload, "context": {}}))
        if kind.endswith(".is_ready"):
            if MODE == "never_ready":
                continue
            await reply(kind + ".response", {"status": True})
        elif kind == "intent.service.intent.get":
            utt = data.get("utterance")
            if MODE == "deaf":
                continue
            if MODE == "no_match":
                await reply("intent.service.intent.reply", {"intent": None, "utterance": utt})
            elif MODE == "wrong_pipeline":
                await reply("intent.service.intent.reply",
                            {"intent": dict(MATCH, intent_service="ovos-adapt-pipeline-plugin-high"),
                             "utterance": utt})
            else:
                await reply("intent.service.intent.reply",
                            {"intent": dict(MATCH), "utterance": utt})
        elif kind == "recognizer_loop:utterance":
            if MODE == "silent_skill":
                continue
            if MODE == "slow_skill":
                # Answers the utterance it was given, but slowly enough that the harness
                # has already asked again by the time it speaks. The reply carries the
                # FIRST ask's marker, and it is still the answer to the question.
                ctx_slow = dict(m.get("context") or {})
                async def answer_later(c):
                    await asyncio.sleep(3)
                    await ws.send(json.dumps({"type": "speak",
                                              "data": {"utterance": "it is half past ten"},
                                              "context": c}))
                if DROPPED[0] == 0:
                    DROPPED[0] += 1
                    asyncio.create_task(answer_later(ctx_slow))
                continue
            if MODE == "restarting_skill":
                # A skills service that is being relaunched is simply not there for the
                # utterance in flight. Dropping the first two and answering the third is
                # what that looks like from the bus: nothing is refused, nothing errors,
                # the message just lands where no one is listening.
                DROPPED[0] += 1
                if DROPPED[0] <= 2:
                    continue
            if MODE == "chatty_bystander":
                # another skill talking on its own account: no triggering context, so no
                # marker - exactly what must NOT be mistaken for the answer
                await ws.send(json.dumps({"type": "speak",
                                          "data": {"utterance": "ready to go"},
                                          "context": {"skill_id": "boot-finished"}}))
                continue
            ctx = dict(m.get("context") or {})
            await ws.send(json.dumps({"type": "speak",
                                      "data": {"utterance": "no problem, stopping"},
                                      "context": ctx}))

async def main():
    async with websockets.serve(handler, "127.0.0.1", PORT):
        print("ready", flush=True)
        await asyncio.Future()

asyncio.run(main())
"""


class FakeBus:
    """An OVOS messagebus that answers correctly, or in one chosen wrong way.

    Run as a subprocess rather than a thread: each case then gets its own event loop and
    its own socket, which is what keeps one broken-on-purpose case from contaminating the
    next.
    """

    _next_port = [8271]

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


def run_harness(*args, port, speak_timeout="4", attempt_window="20"):
    result = subprocess.run(
        [sys.executable, str(HARNESS), "--url", f"ws://127.0.0.1:{port}/core",
         "--connect-timeout", "4", "--ready-timeout", "6",
         "--reply-timeout", "4", "--speak-timeout", speak_timeout,
         f"--speak-attempt-window={attempt_window}", *args],
        capture_output=True, text=True, timeout=90)
    return result.returncode, result.stdout + result.stderr


@unittest.skipUnless(HAVE_SERVER and HAVE_CLIENT,
                     "needs websockets (server) and websocket-client (harness)")
class EachRungCanFail(unittest.TestCase):
    """Every rung, driven over a real socket, in its healthy and its broken state."""

    def test_a_healthy_deployment_passes_the_whole_ladder(self):
        with FakeBus("healthy") as bus:
            code, out = run_harness("--expect-match", "--expect-pipeline", "ovos-stop",
                                    "--expect-speak", port=bus.port)
        self.assertEqual(code, 0, out)
        self.assertIn("talking to each other", out)

    def test_a_bus_nobody_is_listening_on_fails_first(self):
        code, out = run_harness(port=8299)   # nothing bound here
        self.assertEqual(code, 1, out)
        self.assertIn("nothing is listening", out)

    def test_a_core_that_never_reports_ready_fails(self):
        with FakeBus("never_ready") as bus:
            code, out = run_harness(port=bus.port)
        self.assertEqual(code, 1, out)
        self.assertIn("never reported ready", out)

    def test_an_intent_service_that_stops_answering_fails(self):
        with FakeBus("deaf") as bus:
            code, out = run_harness(port=bus.port)
        self.assertEqual(code, 1, out)
        self.assertIn("did not answer a probe", out)

    def test_no_match_fails_only_when_a_match_was_required(self):
        with FakeBus("no_match") as bus:
            self.assertEqual(run_harness(port=bus.port)[0], 0, "no skills installed is not a defect")
            code, out = run_harness("--expect-match", port=bus.port)
        self.assertEqual(code, 1, out)

    def test_the_wrong_pipeline_fails_even_though_the_utterance_resolves(self):
        """The regression this exists for.

        An engine that disappears is covered for by whichever stage remains, so the
        utterance still resolves and nothing else notices. Asserting the stage is the
        only thing that sees it.
        """
        with FakeBus("wrong_pipeline") as bus:
            self.assertEqual(run_harness("--expect-match", port=bus.port)[0], 0,
                             "it does resolve - that is the point")
            code, out = run_harness("--expect-match", "--expect-pipeline", "padatious", port=bus.port)
        self.assertEqual(code, 1, out)
        self.assertIn("covered for by whichever stage remains", out)

    def test_a_skill_that_never_answers_fails_the_round_trip(self):
        with FakeBus("silent_skill") as bus:
            code, out = run_harness("--expect-speak", port=bus.port)
        self.assertEqual(code, 1, out)
        self.assertIn("a skill answering it", out)

    def test_an_utterance_dropped_by_a_restarting_skill_is_asked_again(self):
        """Waiting longer cannot recover a message nobody was listening for.

        A bus utterance is fire-and-forget. When the skills service aborts and launchd
        relaunches it - which is what macOS was doing when this rung failed, with the
        intent still resolving from core - the utterance in flight is simply lost. A
        single-shot wait then reports "nothing spoke" after the whole budget, having
        asked exactly once. Only asking again recovers it.
        """
        with FakeBus("restarting_skill") as bus:
            code, out = run_harness("--expect-speak", port=bus.port,
                                    speak_timeout="24", attempt_window="2")
            self.assertEqual(code, 0, out)
            self.assertIn("a skill answered with", out)

    def test_a_late_answer_to_an_earlier_ask_still_counts(self):
        """Asking again must not invalidate the question already asked.

        The reply carries the marker of the ask it belongs to. If only the newest marker
        were accepted, a skill that answered the first ask a moment after the harness had
        moved on would be thrown away as somebody else's speech, and a deployment that
        works would be reported as one where no skill answered.
        """
        with FakeBus("slow_skill") as bus:
            code, out = run_harness("--expect-speak", port=bus.port,
                                    speak_timeout="24", attempt_window="2")
            self.assertEqual(code, 0, out)
            self.assertIn("half past ten", out)

    def test_an_attempt_window_that_is_not_positive_is_refused(self):
        """Otherwise the re-ask loop becomes a flood.

        A window of zero makes every wait return immediately, so the loop re-sends as
        fast as the socket allows: a three second budget sent the utterance 467,438
        times. nan is refused for the same reason - nan > 0 is False - and because it
        would poison min() and leave the wait with no deadline. Positive infinity is
        allowed, since min() then yields the remaining budget.
        """
        for window in ("0", "-1", "nan", "-inf"):
            with self.subTest(window=window):
                with FakeBus("silent_skill") as bus:
                    code, out = run_harness("--expect-speak", port=bus.port,
                                            speak_timeout="3", attempt_window=window)
                    self.assertEqual(code, 1, out)
                    self.assertIn("must be greater than zero", out)
                    self.assertNotIn("asked", out)

    def test_the_skills_rung_can_be_skipped_for_a_profile_that_runs_none(self):
        with FakeBus("healthy") as bus:
            code, out = run_harness("--skip-skills-ready", port=bus.port)
        self.assertEqual(code, 0, out)
        self.assertNotIn("skills    :", out)


@unittest.skipUnless(HAVE_SERVER and HAVE_CLIENT,
                     "needs websockets (server) and websocket-client (harness)")
class ItAnswersTheQuestionItAsked(unittest.TestCase):
    """Correlating the reply, and refusing to assert about a match that never happened."""

    def test_speech_from_another_skill_is_not_taken_as_the_answer(self):
        """A boot announcement speaks unprompted; it is not a reply to anything.

        Taking the next `speak` on a shared bus would let one of those stand in for an
        answer that never came - a pass with nothing behind it.
        """
        with FakeBus("chatty_bystander") as bus:
            code, out = run_harness("--expect-speak", port=bus.port)
        self.assertEqual(code, 1, out)
        self.assertIn("a skill answering it", out)

    def test_the_answer_carrying_this_probe_marker_is_accepted(self):
        with FakeBus("healthy") as bus:
            code, out = run_harness("--expect-speak", port=bus.port)
        self.assertEqual(code, 0, out)
        self.assertIn("no problem, stopping", out)

    def test_naming_a_pipeline_requires_there_to_be_a_match(self):
        """--expect-pipeline used to skip its check when nothing matched, and pass.

        That is the defect this whole check exists to find, in the check itself: an
        assertion about the match is worthless if the absence of a match satisfies it.
        """
        with FakeBus("no_match") as bus:
            code, out = run_harness("--expect-pipeline", "padatious", port=bus.port)
            self.assertEqual(code, 1, out)
            self.assertEqual(run_harness("--expect-skill", "skill-date-time",
                                         port=bus.port)[0], 1)
            # without an expectation, no match is still a perfectly good answer
            self.assertEqual(run_harness(port=bus.port)[0], 0)


class TheHarnessItself(unittest.TestCase):
    """Holds without either websocket library installed."""

    def test_it_is_executable_and_documents_its_own_flags(self):
        result = subprocess.run([sys.executable, str(HARNESS), "--help"],
                                capture_output=True, text=True, timeout=60)
        self.assertEqual(result.returncode, 0, result.stderr)
        for flag in ("--expect-match", "--expect-pipeline", "--expect-speak",
                     "--skip-skills-ready", "--url"):
            self.assertIn(flag, result.stdout)

    def test_the_default_utterance_needs_no_skills(self):
        """`stop` is answered by core's own stop pipeline, so rungs 1-4 hold bare."""
        result = subprocess.run([sys.executable, str(HARNESS), "--help"],
                                capture_output=True, text=True, timeout=60)
        self.assertIn("stop pipeline", result.stdout)


class TheWrapperPicksAnInterpreterWithoutWritingToHome(unittest.TestCase):
    """Where the dependency lands, when the deployment's own interpreter cannot be used.

    The first real run of this check failed here rather than in the deployment: pip fell
    back to ~/.local, which the installer leaves root-owned because it runs under sudo,
    and the step died with EACCES before reaching the bus. Nothing about the round trip
    needs to write inside HOME, so nothing may.
    """

    WRAPPER = ROOT / ".github" / "scripts" / "assert_intent_roundtrip.sh"

    def run_wrapper(self, home, stub_dir, extra_env=None):
        env = dict(os.environ, HOME=str(home), PATH=f"{stub_dir}:{os.environ['PATH']}",
                   PYTHON_BIN=str(stub_dir / "python3"),
                   OVOS_VENV_PYTHON=str(home / "no-such-venv" / "bin" / "python"))
        env.update(extra_env or {})
        return subprocess.run([str(self.WRAPPER), "--help"], capture_output=True,
                              text=True, timeout=60, env=env)

    def make_stubs(self, tmp, has_websocket=False):
        """A python3 that reports whether websocket is importable, and records pip args."""
        stub = tmp / "bin"
        stub.mkdir(parents=True)
        recorded = tmp / "pip-args"
        (stub / "python3").write_text(
            "#!/bin/bash\n"
            'if [ "$1" = "-c" ] && [ "$2" = "import websocket" ]; then\n'
            f'  exit {0 if has_websocket else 1}\n'
            "fi\n"
            'if [ "$1" = "-m" ] && [ "$2" = "pip" ]; then\n'
            f'  printf "%s\\n" "$@" >> "{recorded}"\n'
            "  exit 0\n"
            "fi\n"
            # the real interpreter by absolute path: the stub is first on PATH, so
            # resolving "python3" here would re-enter this script forever
            f'exec {sys.executable} "$@"\n')
        (stub / "python3").chmod(0o755)
        return stub, recorded

    def test_the_dependency_goes_to_a_throwaway_directory_not_to_home(self):
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            home = tmp / "home"
            (home / ".local" / "lib").mkdir(parents=True)
            stub, recorded = self.make_stubs(tmp, has_websocket=False)
            self.run_wrapper(home, stub)
            args = recorded.read_text() if recorded.exists() else ""
            self.assertIn("--target", args, "the install must be redirected")
            self.assertNotIn("--user", args)
            self.assertNotIn(str(home), args,
                             "nothing may be written inside HOME, which the installer "
                             "leaves root-owned after running under sudo")

    def test_an_interpreter_that_already_has_it_installs_nothing(self):
        with tempfile.TemporaryDirectory() as raw:
            tmp = Path(raw)
            home = tmp / "home"
            home.mkdir()
            stub, recorded = self.make_stubs(tmp, has_websocket=True)
            self.run_wrapper(home, stub)
            # What matters is that it did not reach for pip. The harness's own exit is
            # not asserted here: HOME is faked to keep the test off the real one, and
            # user site-packages hangs off HOME, so the interpreter's import path is
            # not the one it would have in a real run.
            self.assertFalse(recorded.exists(), "it should not have reached for pip")


if __name__ == "__main__":
    unittest.main()

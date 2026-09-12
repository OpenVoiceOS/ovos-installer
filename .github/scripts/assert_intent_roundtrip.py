#!/usr/bin/env python3
"""Prove that the messagebus, core and the skills are talking to each other.

The check beside this one asks whether ovos-padatious is installed. That is a different
question: a package can sit on disk while nothing listens on the bus, while core never
attaches to it, or while the intent pipeline resolves an utterance through some other
stage entirely. An install that fails any of those looks identical from the outside - it
completes, it logs nothing alarming, and it answers no one. Every Linux job in this
repository has, until now, proved only that the installer exited zero; nothing has ever
connected to port 8181.

So this walks a ladder and reports the rung that gave way:

  1. something is listening on the bus         the deployment started at all
  2. the intent service reports ready          core is attached to the bus
  3. the skills service reports ready          the skill layer finished loading
  4. a read-only probe resolves an utterance   the pipeline actually matches, and the
                                               reply names the stage that did - so an
                                               engine that quietly disappears and leaves
                                               another stage to cover for it is visible
  5. an utterance comes back as speech         bus, core and a skill, end to end

Rungs 1-4 hold with no skills installed, because ovos-core answers "stop" itself through
its own stop pipeline. Rung 5 needs a skill that claims the utterance, so it is opt-in.

One script serves both installation methods. ovos-docker runs the messagebus with
network_mode: host, so a containers install and a virtualenv install both put it on
127.0.0.1:8181, and this speaks the bus protocol over a bare websocket rather than
importing ovos-bus-client - which keeps it identical on a host with no venv, inside a
container, and on macOS.
"""
import argparse
import json
import secrets
import sys
import time


class Failure(Exception):
    """A rung that did not hold. The message is what CI prints and a human reads."""


class Bus:
    """The bus protocol, in the small: send a message, wait for a reply type."""

    def __init__(self, url, connect_timeout):
        # Imported here rather than at module scope so that --help, and every argument
        # error, still work on a machine that has not got it yet. A program that cannot
        # explain itself without its dependencies is a worse program to debug in CI.
        try:
            import websocket  # websocket-client, as ovos-docker's own health probe uses
        except ImportError:
            raise Failure("websocket-client is not installed, so the bus cannot be "
                          "reached from this interpreter")
        self.websocket = websocket
        self.url = url
        try:
            self.ws = websocket.create_connection(url, timeout=connect_timeout)
        except Exception as error:
            raise Failure(
                f"nothing is listening on {url} ({type(error).__name__}: {error}). "
                f"The messagebus is not running, so no part of the stack can reach any "
                f"other part."
            )

    def send(self, msg_type, data=None, context=None):
        self.ws.send(json.dumps({"type": msg_type, "data": data or {},
                                 "context": context or {"source": ["ci"]}}))

    def wait_for(self, reply_type, timeout, match=None):
        """Read until `reply_type` arrives, or the deadline passes. None on timeout."""
        deadline = time.monotonic() + timeout
        while True:
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                return None
            self.ws.settimeout(max(0.1, remaining))
            try:
                raw = self.ws.recv()
            except self.websocket.WebSocketTimeoutException:
                return None
            except Exception:
                return None
            try:
                message = json.loads(raw)
            except (TypeError, ValueError):
                continue
            if message.get("type") != reply_type:
                continue
            if match and not match(message):
                continue
            return message

    def ask(self, msg_type, reply_type=None, data=None, context=None, timeout=10,
            match=None):
        self.send(msg_type, data, context)
        return self.wait_for(reply_type or f"{msg_type}.response", timeout, match)

    def close(self):
        try:
            time.sleep(0.5)  # the bus server dislikes an abrupt close
            self.ws.close()
        except Exception:
            pass


def wait_ready(bus, service, timeout, poll=5):
    """`<ns>.<service>.is_ready`, answered with data.status once that half is up.

    Polled rather than slept on: core is seconds old when this runs and a constant sleep
    is either too short on a cold two-core runner or wastes minutes on a warm one.
    """
    msg_type = f"mycroft.{service}.is_ready"
    deadline = time.monotonic() + timeout
    last = None
    while time.monotonic() < deadline:
        answer = bus.ask(msg_type, data={},
                         context={"source": ["ci"], "destination": [service]},
                         timeout=min(poll, max(0.5, deadline - time.monotonic())))
        if answer is not None:
            last = (answer.get("data") or {})
            if last.get("status"):
                return
        time.sleep(0.5)
    raise Failure(
        f"{service} never reported ready within {timeout:.0f}s (last answer: {last!r}). "
        f"The bus is up, so something is running - but this half of the stack never "
        f"finished attaching to it."
    )


def probe(bus, utterance, lang, timeout):
    """intent.service.intent.get - read-only, it never runs a handler."""
    answer = bus.ask("intent.service.intent.get",
                     reply_type="intent.service.intent.reply",
                     data={"utterance": utterance, "lang": lang},
                     context={"source": ["ci"], "lang": lang},
                     timeout=timeout,
                     match=lambda m: (m.get("data") or {}).get("utterance") == utterance)
    if answer is None:
        raise Failure(
            f"the intent service did not answer a probe for {utterance!r} within "
            f"{timeout:.0f}s, having already reported itself ready."
        )
    return (answer.get("data") or {}).get("intent")


# Long enough that a healthy skill answers on the first ask, short enough that a
# dropped utterance is asked again several times inside a --speak-timeout budget.
SPEAK_ATTEMPT_WINDOW = 20.0


def round_trip(bus, utterance, lang, timeout, attempt_window=SPEAK_ATTEMPT_WINDOW):
    """An utterance in, speech out: the whole chain, with a skill on the end of it.

    The reply is correlated with this particular utterance rather than taken as the next
    thing said on the bus. Other skills speak unprompted - a boot announcement is the
    obvious one - and accepting the first `speak` would let one of those stand in for an
    answer that never came. A skill answering inside a handler speaks with
    `message.forward`, which carries the triggering context through, so a marker put on
    the utterance comes back on the reply.

    The utterance is asked again rather than waited on in one go, because a bus message is
    fire-and-forget. A skills service that is not listening at that instant never receives
    the one in flight, and waiting longer cannot recover a message nobody was there for -
    only asking again can. That is not hypothetical: on macOS this service has been seen
    to abort during boot and be relaunched, which leaves the intent resolving from core
    while no skill answers, and a single-shot wait reports that as "nothing spoke" after
    the full budget. Every attempt keeps its marker, so an answer to an earlier attempt
    still counts rather than being discarded as unrecognised.
    """
    deadline = time.monotonic() + timeout
    markers = set()
    attempts = 0
    while True:
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            break
        marker = secrets.token_hex(8)
        markers.add(marker)
        attempts += 1
        bus.send("recognizer_loop:utterance",
                 {"utterances": [utterance], "lang": lang},
                 {"source": ["ci"], "lang": lang, "ci_probe": marker})
        answer = bus.wait_for(
            "speak", min(attempt_window, remaining),
            match=lambda m: (m.get("context") or {}).get("ci_probe") in markers)
        if answer is not None:
            return (answer.get("data") or {}).get("utterance", "")
    raise Failure(
        f"nothing spoke within {timeout:.0f}s of saying {utterance!r}, asked "
        f"{attempts} time{'' if attempts == 1 else 's'}. The intent resolves, so core is "
        f"working - what did not happen is a skill answering it, which is the half this "
        f"exists to prove."
    )


def main(argv=None):
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--url", default="ws://127.0.0.1:8181/core")
    parser.add_argument("--lang", default="en-us")
    parser.add_argument("--utterance", default="stop",
                        help="what to probe. The default is answered by core's own stop "
                             "pipeline, so it resolves with no skills installed at all.")
    parser.add_argument("--connect-timeout", type=float, default=30)
    parser.add_argument("--ready-timeout", type=float, default=300,
                        help="core loads skills before answering; a cold container "
                             "stack on a slow runner is the case this has to cover")
    parser.add_argument("--reply-timeout", type=float, default=30)
    parser.add_argument("--speak-timeout", type=float, default=60)
    parser.add_argument("--speak-attempt-window", type=float,
                        default=SPEAK_ATTEMPT_WINDOW,
                        help="how long to wait for an answer before asking "
                             "again, within the --speak-timeout budget.")
    parser.add_argument("--expect-match", action="store_true",
                        help="require the probe to resolve to an intent")
    parser.add_argument("--expect-pipeline", default=None,
                        help="require the matching stage's name to contain this, e.g. "
                             "'padatious'. Catches an engine that vanished and left "
                             "another stage covering for it.")
    parser.add_argument("--expect-skill", default=None,
                        help="require the match to belong to this skill id")
    parser.add_argument("--expect-speak", action="store_true",
                        help="require a skill to answer out loud (needs a skill that "
                             "claims --utterance)")
    parser.add_argument("--skip-skills-ready", action="store_true",
                        help="do not wait on the skills service, for a profile that "
                             "runs none")
    args = parser.parse_args(argv)

    bus = None
    try:
        bus = Bus(args.url, args.connect_timeout)
        print(f"bus       : listening at {args.url}")

        wait_ready(bus, "intents", args.ready_timeout)
        print("core      : the intent service reports ready")

        if not args.skip_skills_ready:
            wait_ready(bus, "skills", args.ready_timeout)
            print("skills    : the skills service reports ready")

        intent = probe(bus, args.utterance, args.lang, args.reply_timeout)
        if intent:
            print(f"intent    : {args.utterance!r} -> {intent.get('intent_name')} "
                  f"via {intent.get('intent_service')} "
                  f"(skill {intent.get('skill_id')})")
        else:
            print(f"intent    : {args.utterance!r} matched nothing")

        # Naming a pipeline or a skill is a statement about the match, so it requires one.
        # Skipping the check when nothing matched let --expect-pipeline pass while
        # asserting nothing at all, which is the failure this whole check exists to find.
        if (args.expect_match or args.expect_pipeline or args.expect_skill) and not intent:
            raise Failure(
                f"nothing matched {args.utterance!r}. The pipeline answered, so it is "
                f"alive; what it no longer does is resolve this utterance."
            )
        if intent and args.expect_pipeline:
            stage = intent.get("intent_service") or ""
            if args.expect_pipeline not in stage:
                raise Failure(
                    f"{args.utterance!r} was matched by {stage!r}, which is not "
                    f"{args.expect_pipeline!r}. The utterance still resolves, and that "
                    f"is exactly why this is worth asserting: an engine that disappears "
                    f"is covered for by whichever stage remains, and nothing else "
                    f"notices."
                )
        if intent and args.expect_skill and intent.get("skill_id") != args.expect_skill:
            raise Failure(
                f"{args.utterance!r} was claimed by {intent.get('skill_id')!r}, not "
                f"{args.expect_skill!r}."
            )

        if args.expect_speak:
            spoken = round_trip(bus, args.utterance, args.lang, args.speak_timeout,
                                args.speak_attempt_window)
            print(f"speech    : a skill answered with {spoken!r}")

        print("the bus, core and the skills are talking to each other")
        return 0
    except Failure as failure:
        print(f"\nintent round trip failed: {failure}", file=sys.stderr)
        return 1
    finally:
        if bus is not None:
            bus.close()


if __name__ == "__main__":
    sys.exit(main())

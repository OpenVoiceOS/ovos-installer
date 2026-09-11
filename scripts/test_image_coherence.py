#!/usr/bin/env python3
"""Offline tests for the image coherence decision logic.

The check itself needs a registry, so these build a real throwaway git repository instead and
drive the decisions that matter: which direction the image sits relative to the pin, whether the
producer's own selector says this image would be rebuilt, and - the case that makes the whole
thing worth having - that an image sitting behind the pin by a harmless commit stays quiet.

Every guard here is asserted in both directions. A check that only ever passes proves nothing.
"""
import subprocess
import sys
import tempfile
import time
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import image_coherence as ic  # noqa: E402


def git(repo, *args):
    subprocess.run(["git", "-C", str(repo), *args], check=True,
                   capture_output=True, text=True)


def commit(repo, path, body, message):
    target = repo / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(body)
    git(repo, "add", "-A")
    git(repo, "-c", "user.email=t@t", "-c", "user.name=t", "commit", "-q", "-m", message)
    return subprocess.run(["git", "-C", str(repo), "rev-parse", "HEAD"],
                          capture_output=True, text=True, check=True).stdout.strip()


# A stand-in for the producer's selector: rebuilds "app" only when app/ changed. The real one is
# scripts/affected.py in the producer repository; this asserts we drive it correctly, not that it
# is correct - that is its own repository's tests.
SELECTOR = """#!/usr/bin/env python3
import json, sys
files = [l.strip() for l in sys.stdin if l.strip()]
print(json.dumps(sorted({"app" for f in files if f.startswith("app/")})))
"""


class ImageCoherence(unittest.TestCase):

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self._tmp.name) / "producer"
        self.repo.mkdir()
        git(self.repo, "init", "-q")
        commit(self.repo, "scripts/affected.py", SELECTOR, "selector")
        self.base = commit(self.repo, "app/Dockerfile", "FROM scratch\n", "app")
        self.docs_only = commit(self.repo, "README.md", "docs\n", "docs only")
        self.app_change = commit(self.repo, "app/Dockerfile", "FROM scratch\nRUN true\n", "app change")

    def tearDown(self):
        self._tmp.cleanup()

    # --- canonical_image -------------------------------------------------------------------
    def test_canonical_image_matches_the_producers_spelling(self):
        self.assertEqual(ic.canonical_image("smartgic/ovos-core:${VERSION}"),
                         "docker.io/smartgic/ovos-core")
        self.assertEqual(ic.canonical_image("ghcr.io/openvoiceos/x:${VERSION}"),
                         "ghcr.io/openvoiceos/x")
        # a registry is recognised by the dot, not by a list of known hosts
        self.assertEqual(ic.canonical_image("localhost:5000/x:${VERSION}"), "localhost:5000/x")

    # --- the rebuild oracle ----------------------------------------------------------------
    def test_a_harmless_commit_rebuilds_nothing(self):
        """The case this check exists to stay quiet about."""
        targets, reason = ic.rebuild_targets(self.repo, self.base, self.docs_only)
        self.assertIsNone(reason)
        self.assertEqual(targets, [])

    def test_a_change_under_the_build_context_rebuilds_the_image(self):
        targets, reason = ic.rebuild_targets(self.repo, self.docs_only, self.app_change)
        self.assertIsNone(reason)
        self.assertEqual(targets, ["app"])

    def test_an_unreachable_revision_is_not_reported_as_clean(self):
        targets, reason = ic.rebuild_targets(self.repo, "0" * 40, self.app_change)
        self.assertIsNone(targets)
        self.assertIn("not reachable", reason)

    # --- direction -------------------------------------------------------------------------
    def test_image_behind_by_a_harmless_commit_is_coherent(self):
        verdict, detail = ic.compare(self.repo, self.docs_only, self.base,
                                     "img", {"img": "app"}, {}, self.repo, self.docs_only)
        self.assertEqual(verdict, "coherent", detail)

    def test_image_behind_by_a_rebuilding_commit_is_flagged(self):
        verdict, detail = ic.compare(self.repo, self.app_change, self.docs_only,
                                     "img", {"img": "app"}, {}, self.repo, self.app_change)
        self.assertEqual(verdict, "behind", detail)
        self.assertIn("app", detail)

    def test_built_from_the_pinned_tree_is_coherent(self):
        verdict, _ = ic.compare(self.repo, self.app_change, self.app_change,
                                "img", {"img": "app"}, {}, self.repo, self.app_change)
        self.assertEqual(verdict, "coherent")

    def test_missing_bake_target_is_unknown_not_clean(self):
        """An image nothing can attribute must not be reported as verified."""
        verdict, detail = ic.compare(self.repo, self.app_change, self.base,
                                     "img", {}, {}, self.repo, self.app_change)
        self.assertEqual(verdict, "unknown", detail)

    def test_missing_bake_graph_is_unknown_not_clean(self):
        verdict, detail = ic.compare(self.repo, self.app_change, self.base,
                                     "img", None, {}, self.repo, self.app_change)
        self.assertEqual(verdict, "unknown", detail)
        self.assertIn("bake graph", detail)

    def test_unreachable_revision_is_unknown(self):
        verdict, detail = ic.compare(self.repo, self.app_change, "0" * 40,
                                     "img", {"img": "app"}, {}, self.repo, self.app_change)
        self.assertEqual(verdict, "unknown", detail)

    # --- service interface (the ahead direction) -------------------------------------------
    def test_service_interface_reports_keys_not_values(self):
        compose = ("services:\n  svc:\n    image: x:${VERSION}\n"
                   "    environment:\n      A: one\n      B: two\n"
                   "    volumes:\n      - ./h:/container/path:ro\n")
        rev = commit(self.repo, "compose/docker-compose.yml", compose, "compose")
        face = ic.service_interface(self.repo, rev, "docker-compose.yml", "svc")
        self.assertEqual(face["environment"], ["A", "B"])
        self.assertEqual(face["volumes"], ["/container/path"])

        # changing a VALUE is the installer's business and must not read as an interface change
        same = compose.replace("A: one", "A: changed")
        rev2 = commit(self.repo, "compose/docker-compose.yml", same, "value change")
        self.assertEqual(ic.service_interface(self.repo, rev2, "docker-compose.yml", "svc"), face)

        # adding a KEY is the image's business and must
        more = compose.replace("      B: two\n", "      B: two\n      C: three\n")
        rev3 = commit(self.repo, "compose/docker-compose.yml", more, "key added")
        self.assertNotEqual(ic.service_interface(self.repo, rev3, "docker-compose.yml", "svc"), face)



class UnreleasedImpact(unittest.TestCase):
    """A release trailing its branch only matters when an install can see the difference."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self._tmp.name) / "producer"
        self.repo.mkdir()
        git(self.repo, "init", "-q")
        git(self.repo, "checkout", "-q", "-b", "dev")
        commit(self.repo, "scripts/affected.py", SELECTOR, "selector")
        commit(self.repo, "compose/docker-compose.yml", "services: {}\n", "compose")
        commit(self.repo, "app/Dockerfile", "FROM scratch\n", "app")
        git(self.repo, "tag", "v1.0.0")
        # a clone cannot fetch from itself, so the tests point the function at this repo as both
        git(self.repo, "remote", "add", "origin", str(self.repo))

    def tearDown(self):
        self._tmp.cleanup()

    def test_ci_only_commits_do_not_warrant_a_release(self):
        commit(self.repo, ".github/workflows/ci.yml", "on: push\n", "ci only")
        commit(self.repo, "scripts/helper.py", "# tooling\n", "tooling only")
        affects, detail = ic.unreleased_impact(self.repo, "v1.0.0", "dev", {"docker-compose.yml"})
        self.assertFalse(affects, detail)
        self.assertIn("no install consumes", detail)

    def test_a_compose_change_an_install_runs_does_warrant_one(self):
        commit(self.repo, "compose/docker-compose.yml", "services: {x: {}}\n", "compose change")
        affects, detail = ic.unreleased_impact(self.repo, "v1.0.0", "dev", {"docker-compose.yml"})
        self.assertTrue(affects, detail)
        self.assertIn("docker-compose.yml", detail)

    def test_a_compose_file_this_installer_does_not_run_is_ignored(self):
        commit(self.repo, "compose/docker-compose.other.yml", "services: {}\n", "other compose")
        affects, detail = ic.unreleased_impact(self.repo, "v1.0.0", "dev", {"docker-compose.yml"})
        self.assertFalse(affects, detail)

    def test_a_rebuild_the_channel_tag_already_delivers_does_not_warrant_one(self):
        """The asymmetry the whole checker rests on.

        Compose files are read from the clone at the PINNED tag, so a compose change reaches
        nobody until a release. Images are pulled by a MOVING channel tag, so a Dockerfile
        change reaches every install on the next publish with no release at all. Calling that
        a release lag would page a human weekly for work already delivered.
        """
        commit(self.repo, "app/Dockerfile", "FROM scratch\nRUN true\n", "image change")
        affects, detail = ic.unreleased_impact(self.repo, "v1.0.0", "dev", {"docker-compose.yml"})
        self.assertFalse(affects, detail)
        self.assertIn("channel tag", detail)

    def test_a_compose_change_is_still_reported_when_it_also_rebuilds_images(self):
        """The image rebuild must not swallow the compose change riding along with it."""
        commit(self.repo, "compose/docker-compose.yml", "services: {x: {}}\n", "compose change")
        commit(self.repo, "app/Dockerfile", "FROM scratch\nRUN true\n", "image change")
        affects, detail = ic.unreleased_impact(self.repo, "v1.0.0", "dev", {"docker-compose.yml"})
        self.assertTrue(affects, detail)
        self.assertIn("docker-compose.yml", detail)
        self.assertIn("also rebuilds", detail)

    def test_nothing_unreleased_is_not_an_impact(self):
        affects, detail = ic.unreleased_impact(self.repo, "v1.0.0", "dev", {"docker-compose.yml"})
        self.assertFalse(affects, detail)



class CheckImagesReporting(unittest.TestCase):
    """What check_images turns into output.

    None of this was covered before: every guard lived in a branch no test drove, so the audit
    found four ways a run could verify nothing and still report success. These assert the
    reporting contract itself - an unresolved image must be visible in the coverage count AND
    reachable by --fail-on-image-drift, never a note that cannot fail anything.
    """

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.root = Path(self._tmp.name)
        self.repo = self.root / "producer"
        self.repo.mkdir()
        git(self.repo, "init", "-q")
        commit(self.repo, "scripts/affected.py", SELECTOR, "selector")
        self.pin = commit(self.repo, "compose/docker-compose.yml",
                          "services:\n  app:\n    image: smartgic/app:${VERSION}\n", "compose")
        git(self.repo, "tag", "v1.0.0")

        self.facts = {
            "compose_files": {"producer": {"docker-compose.yml"}},
            "pins": {"producer": "v1.0.0"},
            "slugs": {"producer": "Org/producer"},
        }
        self.contracts = {"producer": {"images": ["docker.io/smartgic/app"]}}
        self._real = (ic.pin_clone, ic.target_images, ic.read_labels)
        ic.pin_clone = lambda slug, ref, cache: self.repo
        ic.target_images = lambda clone: {"docker.io/smartgic/app": "app"}

    def tearDown(self):
        ic.pin_clone, ic.target_images, ic.read_labels = self._real
        self._tmp.cleanup()

    def run_check(self):
        return ic.check_images(self.contracts, self.facts, self.root / "cache", "testing")

    def test_an_unreachable_registry_is_not_counted_as_verified(self):
        ic.read_labels = lambda path, tag, **_: (None, "transport")
        problems, notes, coverage = self.run_check()
        self.assertEqual(coverage[("producer", "testing")], (0, 1))
        self.assertTrue(any("could not be reached" in n for n in notes), notes)

    def test_a_missing_channel_tag_is_a_problem_not_a_note(self):
        """An install pulling a tag that does not exist fails; that is a finding."""
        ic.read_labels = lambda path, tag, **_: (None, "no_tag")
        problems, notes, coverage = self.run_check()
        self.assertTrue(any("no :testing tag is published" in p for p in problems), problems)

    def test_an_undecided_verdict_does_not_count_toward_coverage(self):
        ic.target_images = lambda clone: None          # no bake graph -> cannot attribute
        ic.read_labels = lambda path, tag, **_: (
            {"org.opencontainers.image.revision": "0" * 40,
             "org.opencontainers.image.source": "https://github.com/Org/producer"}, "ok")
        problems, notes, coverage = self.run_check()
        self.assertEqual(coverage[("producer", "testing")], (0, 1))

    def test_a_repository_that_cannot_be_cloned_still_gets_a_coverage_entry(self):
        def boom(slug, ref, cache):
            raise RuntimeError("network down")
        ic.pin_clone = boom
        problems, notes, coverage = self.run_check()
        self.assertIn(("producer", "testing"), coverage)
        self.assertTrue(any("could not clone" in p for p in problems), problems)


    def test_an_image_skipped_for_budget_is_missing_from_coverage(self):
        """The wiring, not the unit.

        A budget-skipped image is never asked about, so it must stay OUT of the resolved count
        while remaining IN the denominator - that gap is what check_contracts turns into a
        violation. A note saying "12 images not verified" cannot fail a job on its own.
        """
        ic.read_labels = lambda path, tag, **_: (None, "budget")
        problems, notes, coverage = self.run_check()
        resolved, total = coverage[("producer", "testing")]
        self.assertEqual(resolved, 0)
        self.assertEqual(total, 1, "the skipped image still counts against what was claimed")
        self.assertTrue(any("budget" in n for n in notes), notes)

    def test_a_self_pinned_image_is_reported_as_out_of_scope(self):
        """Excluding it from the check is right; excluding it from the report is not."""
        real = ic.deployed_images
        try:
            ic.deployed_images = lambda clone, ref, names: (
                {}, [], [("redis:7-alpine", "docker-compose.yml:cache")])
            problems, notes, coverage = self.run_check()
        finally:
            ic.deployed_images = real
        self.assertTrue(any("out of scope" in n and "redis:7-alpine" in n for n in notes), notes)
        self.assertEqual(problems, [], "a pinned image is not a defect")

    def test_an_image_built_elsewhere_leaves_the_denominator_too(self):
        """"Could not tell" and "not ours to tell" are different, and only one is a defect.

        Every other unresolved outcome counts against coverage, which is what turns it into a
        violation. This one would fail the weekly job forever over an image nobody can act on,
        while the note beside it said "out of scope" - the report and the exit status
        disagreeing about the same image.
        """
        ic.read_labels = lambda path, tag, **_: (
            {"org.opencontainers.image.revision": "0" * 40,
             "org.opencontainers.image.source": "https://github.com/SomeoneElse/their-repo"}, "ok")
        problems, notes, coverage = self.run_check()
        self.assertEqual(coverage[("producer", "testing")], (0, 0))
        self.assertTrue(any("out of scope" in n for n in notes), notes)

    def test_an_image_naming_no_source_still_counts_against_coverage(self):
        """A missing label looks exactly like a third-party image, and is not one.

        If a producer's build stopped emitting org.opencontainers.image.source, every image
        would read as "built elsewhere" and quietly leave the denominator - a run that verified
        nothing would report full coverage and pass. Absent is not the same as elsewhere.
        """
        ic.read_labels = lambda path, tag, **_: (
            {"org.opencontainers.image.revision": "0" * 40}, "ok")   # no source label
        problems, notes, coverage = self.run_check()
        self.assertEqual(coverage[("producer", "testing")], (0, 1),
                         "an unattributable image stays in the denominator")
        self.assertTrue(any("names no source repository" in n for n in notes), notes)

    def test_every_outcome_either_resolves_or_is_visible(self):
        """The invariant, swept across every outcome rather than one case at a time.

        A deployed image must do exactly one of three things: reach a verdict and count as
        resolved, be declared out of scope and leave the denominator with a note naming it, or
        leave a gap between resolved and the total. The third is what the caller asserts, so a
        new outcome added later cannot quietly become a fourth kind that counts as verified
        without deciding anything.
        """
        OUTCOMES = {
            "transport": "gap", "denied": "gap", "no_tag": "gap", "budget": "gap",
            "no_revision": "gap", "no_source": "gap", "elsewhere": "out_of_scope",
            "ours": "resolved",
        }
        for outcome, expected in OUTCOMES.items():
            with self.subTest(outcome=outcome):
                if outcome == "no_revision":
                    labels = {"org.opencontainers.image.source": "https://github.com/Org/producer"}
                    ic.read_labels = lambda p, t, **_: (dict(labels), "ok")
                elif outcome == "no_source":
                    ic.read_labels = lambda p, t, **_: (
                        {"org.opencontainers.image.revision": "0" * 40}, "ok")
                elif outcome == "elsewhere":
                    ic.read_labels = lambda p, t, **_: (
                        {"org.opencontainers.image.revision": "0" * 40,
                         "org.opencontainers.image.source": "https://github.com/Other/repo"}, "ok")
                elif outcome == "ours":
                    ic.read_labels = lambda p, t, **_: (
                        {"org.opencontainers.image.revision": self.pin,
                         "org.opencontainers.image.source": "https://github.com/Org/producer"}, "ok")
                else:
                    ic.read_labels = (lambda o: lambda p, t, **_: (None, o))(outcome)

                problems, notes, coverage = self.run_check()
                resolved, total = coverage[("producer", "testing")]
                if expected == "resolved":
                    self.assertEqual((resolved, total), (1, 1))
                elif expected == "out_of_scope":
                    self.assertEqual((resolved, total), (0, 0), "left the denominator")
                    self.assertTrue(any("out of scope" in n for n in notes), notes)
                else:
                    self.assertEqual((resolved, total), (0, 1),
                                     f"{outcome} must leave a visible gap")

    def test_a_compose_file_that_could_not_be_read_is_a_problem(self):
        """Its images are not in `deployed` at all, so coverage alone cannot notice them."""
        real = ic.deployed_images
        try:
            ic.deployed_images = lambda clone, ref, names: (
                {}, [("docker-compose.yml", "is not valid YAML (mapping values not allowed)")], [])
            problems, notes, coverage = self.run_check()
        finally:
            ic.deployed_images = real
        self.assertTrue(any("coverage is narrower than it looks" in p for p in problems), problems)

    def test_an_image_the_contract_does_not_declare_is_a_problem(self):
        self.contracts = {"producer": {"images": []}}
        ic.read_labels = lambda path, tag, **_: (None, "transport")
        problems, notes, coverage = self.run_check()
        self.assertTrue(any("does not declare it" in p for p in problems), problems)

    def test_the_most_severe_mirror_outcome_wins(self):
        """Candidates are tried in order; the last one's outcome must not decide."""
        seen = []

        def by_candidate(path, tag, **_):
            seen.append(path)
            return (None, "transport" if len(seen) == 1 else "no_tag")

        self.facts["slugs"]["other"] = "Org/other"
        self.facts["compose_files"]["other"] = set()
        self.facts["pins"]["other"] = "v1.0.0"
        self.contracts["other"] = {"images": []}
        ic.read_labels = by_candidate
        problems, notes, coverage = self.run_check()
        self.assertTrue(any("could not be reached" in n for n in notes), notes)


class AheadDirection(unittest.TestCase):
    """Ahead of the pin, with the service definition unreadable, is not agreement."""

    def setUp(self):
        self._tmp = tempfile.TemporaryDirectory()
        self.repo = Path(self._tmp.name) / "producer"
        self.repo.mkdir()
        git(self.repo, "init", "-q")
        commit(self.repo, "scripts/affected.py", SELECTOR, "selector")
        self.pin = commit(self.repo, "app/Dockerfile", "FROM scratch\n", "pin")
        self.newer = commit(self.repo, "app/Dockerfile", "FROM scratch\nRUN true\n", "newer")
        self.other = Path(self._tmp.name) / "other"
        self.other.mkdir()
        git(self.other, "init", "-q")
        commit(self.other, "README.md", "x\n", "other repo")

    def tearDown(self):
        self._tmp.cleanup()

    def test_unreadable_service_definition_is_unknown_not_coherent(self):
        verdict, detail = ic.compare(self.repo, self.pin, self.newer, "img", {"img": "app"},
                                     {"docker-compose.yml": "app"}, self.repo, self.pin)
        self.assertEqual(verdict, "unknown", detail)

    def test_a_cross_repository_image_is_not_compared_against_the_wrong_tree(self):
        """The compose file belongs to the deployer, not the builder."""
        verdict, detail = ic.compare(self.repo, self.pin, self.newer, "img", {"img": "app"},
                                     {"docker-compose.hivemind.yml": "cli"}, self.other, "HEAD")
        self.assertEqual(verdict, "unknown", detail)
        self.assertIn("another repository", detail)



class RegistryRetry(unittest.TestCase):
    """Telling a hiccup apart from an outage.

    Making an unreachable registry a failure is only safe if a blip is not one. A run reads
    around thirty images at three or four requests each, so over enough weeks a single transient
    failure is close to certain - and a job that goes red for reasons nobody can act on gets
    muted, which costs every check it was carrying.
    """

    def setUp(self):
        self._once = ic._read_labels_once
        self.slept = []

    def tearDown(self):
        ic._read_labels_once = self._once

    def stub(self, *outcomes):
        """Answer with each outcome in turn, then repeat the last."""
        calls = []

        def once(path, tag):
            calls.append(path)
            index = min(len(calls) - 1, len(outcomes) - 1)
            return outcomes[index]

        ic._read_labels_once = once
        return calls

    def test_a_transient_failure_is_retried_and_recovers(self):
        calls = self.stub((None, "transport"), ({"a": "b"}, "ok"))
        labels, outcome = ic.read_labels("org/img", "testing", sleep=self.slept.append)
        self.assertEqual((labels, outcome), ({"a": "b"}, "ok"))
        self.assertEqual(len(calls), 2)

    def test_a_persistent_outage_still_fails(self):
        calls = self.stub((None, "transport"))
        labels, outcome = ic.read_labels("org/img", "testing", sleep=self.slept.append)
        self.assertEqual(outcome, "transport")
        self.assertEqual(len(calls), ic.REGISTRY_ATTEMPTS)

    def test_a_definitive_answer_is_not_retried(self):
        """404 and 401 are answers. Asking again only spends requests against a rate limit."""
        for decisive in ("no_tag", "denied", "ok"):
            calls = self.stub((None, decisive))
            ic.read_labels("org/img", "testing", sleep=self.slept.append)
            self.assertEqual(len(calls), 1, decisive)

    def test_the_backoff_grows_and_is_bounded(self):
        self.stub((None, "transport"))
        ic.read_labels("org/img", "testing", sleep=self.slept.append)
        self.assertEqual(len(self.slept), ic.REGISTRY_ATTEMPTS - 1)  # no sleep after the last try
        self.assertEqual(self.slept, sorted(self.slept))
        self.assertLess(sum(self.slept), 60)  # a stuck registry must not stall the whole run



class HangingIsFailing(unittest.TestCase):
    """A command that never returns must reach the same handler as one that fails.

    Every git, gh and docker call this program makes talks to a network or a daemon, and none of
    them carried a ceiling: a blackholed fetch simply never returned. The only bound was the
    job's own timeout, and a job killed by that reports nothing at all - including the images it
    had already resolved. That is the same outcome the registry budget exists to avoid.
    """

    def test_a_timeout_is_raised_as_a_failed_command(self):
        """Callers catch CalledProcessError. None of them catches TimeoutExpired."""
        with self.assertRaises(subprocess.CalledProcessError) as caught:
            ic.run(["sleep", "5"], timeout=0.2)
        self.assertEqual(caught.exception.returncode, 124)
        self.assertIn("no answer after", caught.exception.stderr)

    def test_a_hung_command_degrades_one_answer_rather_than_the_run(self):
        """deployed_images already treats a failed git show as a file it could not read."""
        real = ic.run
        try:
            ic.run = lambda *a, **k: real(["sleep", "5"], timeout=0.2)
            found, unreadable, self_pinned = ic.deployed_images(Path(tempfile.gettempdir()), "HEAD",
                                                  ["docker-compose.yml"])
        finally:
            ic.run = real
        self.assertEqual(found, {})
        self.assertEqual([name for name, _ in unreadable], ["docker-compose.yml"])

    def test_a_caller_that_asks_for_no_ceiling_still_gets_one(self):
        """Every call site relies on the default; none of them passes a timeout."""
        seen = {}
        real = subprocess.run

        def capture(*args, **kwargs):
            seen.update(kwargs)
            return real(["true"], capture_output=True, text=True)

        subprocess.run = capture
        try:
            ic.run(["git", "status"])
        finally:
            subprocess.run = real
        self.assertIsNotNone(seen.get("timeout"), "run() passed no ceiling to subprocess")
        self.assertEqual(seen["timeout"], ic.SUBPROCESS_TIMEOUT)

    def test_the_default_ceiling_is_bounded_and_generous(self):
        self.assertLessEqual(ic.SUBPROCESS_TIMEOUT, 600)
        self.assertGreaterEqual(ic.SUBPROCESS_TIMEOUT, 60)


if __name__ == "__main__":
    unittest.main(verbosity=2)


class CoverageScopeIsNotSilentlyNarrowed(unittest.TestCase):
    """A compose file the run could not read must not shrink what it claims to cover."""

    def test_an_unparseable_compose_is_named_rather_than_skipped(self):
        real_run = ic.run
        try:
            ic.run = lambda cmd, *a, **k: type("R", (), {"stdout": "services: [broken: : :"})()
            found, unreadable, self_pinned = ic.deployed_images(
                Path(tempfile.gettempdir()), "HEAD", ["docker-compose.yml"])
        finally:
            ic.run = real_run
        self.assertEqual(found, {}, "nothing is parsed out of a broken file")
        self.assertEqual([name for name, _ in unreadable], ["docker-compose.yml"])
        self.assertIn("not valid YAML", unreadable[0][1])


    def test_an_image_the_compose_pins_itself_is_out_of_scope_and_named(self):
        """The check asks what :<channel> holds. A self-pinned image has no such question.

        Asking anyway looks the image up under a producer mirror that has no such tag and
        reports that an install pulling it would fail - untrue, and unfixable by anyone, which
        is how a weekly alarm gets muted. It is named rather than dropped, because out of scope
        is a defensible answer and out of sight is not.
        """
        real = ic.run
        try:
            ic.run = lambda *a, **k: type("R", (), {"stdout": (
                "services:\n"
                "  app:\n    image: smartgic/app:${VERSION}\n"
                "  cache:\n    image: redis:7-alpine\n"
                "  db:\n    image: postgres\n")})()
            found, unreadable, self_pinned = ic.deployed_images(
                Path(tempfile.gettempdir()), "HEAD", ["docker-compose.yml"])
        finally:
            ic.run = real
        self.assertEqual(sorted(found), ["docker.io/smartgic/app"])
        self.assertEqual(unreadable, [])
        # both the fixed tag and the absent one: the compose decides each, not the channel
        self.assertEqual(sorted(image for image, _ in self_pinned), ["postgres", "redis:7-alpine"])
        self.assertTrue(all(where.startswith("docker-compose.yml:") for _, where in self_pinned))

    def test_a_compose_missing_from_the_pinned_tree_is_named(self):
        real_run = ic.run

        def boom(cmd, *a, **k):
            raise subprocess.CalledProcessError(128, cmd)

        try:
            ic.run = boom
            found, unreadable, self_pinned = ic.deployed_images(
                Path(tempfile.gettempdir()), "HEAD", ["docker-compose.yml"])
        finally:
            ic.run = real_run
        self.assertEqual(found, {})
        self.assertIn("not in the pinned tree", unreadable[0][1])

    def test_a_readable_compose_reports_nothing_unreadable(self):
        real_run = ic.run
        try:
            ic.run = lambda cmd, *a, **k: type(
                "R", (), {"stdout": "services:\n  app:\n    image: smartgic/app:${VERSION}\n"})()
            found, unreadable, self_pinned = ic.deployed_images(
                Path(tempfile.gettempdir()), "HEAD", ["docker-compose.yml"])
        finally:
            ic.run = real_run
        self.assertEqual(unreadable, [])
        self.assertTrue(found)


class RegistryReadsAreBounded(unittest.TestCase):
    """Every registry read in a run shares one wall-clock ceiling.

    Each candidate can cost REGISTRY_TIMEOUT * REGISTRY_ATTEMPTS plus backoff, and a run
    reads up to two candidates per deployed image, so a wide outage scales past the job's
    own timeout. Being killed mid-check reports nothing at all, including what resolved.
    """

    def setUp(self):
        self._real_once = ic._read_labels_once
        self.calls = []
        ic._read_labels_once = lambda path, tag: (self.calls.append(path), (None, "transport"))[1]

    def tearDown(self):
        ic._read_labels_once = self._real_once

    def test_no_request_is_made_once_the_budget_is_spent(self):
        labels, outcome = ic.read_labels(
            "ghcr.io/x/y", "alpha", sleep=lambda s: None, deadline=time.monotonic() - 1)
        self.assertEqual(outcome, "budget")
        self.assertEqual(self.calls, [], "a spent budget makes no request at all")

    def test_a_live_budget_still_retries(self):
        labels, outcome = ic.read_labels(
            "ghcr.io/x/y", "alpha", sleep=lambda s: None, deadline=time.monotonic() + 600)
        self.assertEqual(outcome, "transport")
        self.assertEqual(len(self.calls), ic.REGISTRY_ATTEMPTS)

    def test_a_backoff_that_crosses_the_deadline_makes_no_further_request(self):
        """Checking beside the wait but not after it left one more request spendable.

        Deterministic rather than timing-dependent: the stub sleep moves a fake clock past the
        deadline, so the retry is attempted at exactly the instant the budget runs out.
        """
        now = [1000.0]
        real_monotonic = ic.time.monotonic
        ic.time.monotonic = lambda: now[0]
        try:
            labels, outcome = ic.read_labels(
                "ghcr.io/x/y", "alpha",
                sleep=lambda seconds: now.__setitem__(0, now[0] + 3600),  # overshoot the budget
                deadline=now[0] + 1)
        finally:
            ic.time.monotonic = real_monotonic
        self.assertEqual(len(self.calls), 1, "the retry must not start after the budget is gone")
        self.assertEqual(outcome, "transport",
                         "an attempt was made and failed, which is the more useful answer")

    def test_without_a_deadline_behaviour_is_unchanged(self):
        labels, outcome = ic.read_labels("ghcr.io/x/y", "alpha", sleep=lambda s: None)
        self.assertEqual(len(self.calls), ic.REGISTRY_ATTEMPTS)

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
        commit(self.repo, "compose/docker-compose.yml",
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
        ic.read_labels = lambda path, tag: (None, "transport")
        problems, notes, coverage = self.run_check()
        self.assertEqual(coverage[("producer", "testing")], (0, 1))
        self.assertTrue(any("could not be reached" in n for n in notes), notes)

    def test_a_missing_channel_tag_is_a_problem_not_a_note(self):
        """An install pulling a tag that does not exist fails; that is a finding."""
        ic.read_labels = lambda path, tag: (None, "no_tag")
        problems, notes, coverage = self.run_check()
        self.assertTrue(any("no :testing tag is published" in p for p in problems), problems)

    def test_an_undecided_verdict_does_not_count_toward_coverage(self):
        ic.target_images = lambda clone: None          # no bake graph -> cannot attribute
        ic.read_labels = lambda path, tag: (
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

    def test_an_image_the_contract_does_not_declare_is_a_problem(self):
        self.contracts = {"producer": {"images": []}}
        ic.read_labels = lambda path, tag: (None, "transport")
        problems, notes, coverage = self.run_check()
        self.assertTrue(any("does not declare it" in p for p in problems), problems)

    def test_the_most_severe_mirror_outcome_wins(self):
        """Candidates are tried in order; the last one's outcome must not decide."""
        seen = []

        def by_candidate(path, tag):
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


if __name__ == "__main__":
    unittest.main(verbosity=2)

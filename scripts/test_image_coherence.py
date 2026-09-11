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

    def test_a_change_that_rebuilds_an_image_does_warrant_one(self):
        commit(self.repo, "app/Dockerfile", "FROM scratch\nRUN true\n", "image change")
        affects, detail = ic.unreleased_impact(self.repo, "v1.0.0", "dev", {"docker-compose.yml"})
        self.assertTrue(affects, detail)
        self.assertIn("rebuilds", detail)

    def test_nothing_unreleased_is_not_an_impact(self):
        affects, detail = ic.unreleased_impact(self.repo, "v1.0.0", "dev", {"docker-compose.yml"})
        self.assertFalse(affects, detail)


if __name__ == "__main__":
    unittest.main(verbosity=2)

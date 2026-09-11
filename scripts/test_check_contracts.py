"""What a contract run REPORTS, as opposed to what it checks.

Every test here drives main() the way the scheduled job does, with only the network seams
stubbed. That matters: an adversarial audit of this checker found that the four ways it could
fail to verify anything all ended in notes, and notes cannot fail a job. A run that reached no
verdict about any image printed its counts and exited 0. The counts were real; nothing asserted
them. So these tests assert the exit status, not the text - the exit status is the only part of
this program the weekly job can act on.
"""

import io
import sys
import unittest
from contextlib import redirect_stdout, redirect_stderr
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

import check_contracts as cc
import image_coherence as ic


class ReportingContract(unittest.TestCase):
    def setUp(self):
        self._saved = (cc.fetch, cc.latest_release, cc.release_lag, ic.check_images, sys.argv)
        # Offline by construction: every seam that would touch a network is answered here.
        cc.fetch = lambda slug, ref, path: (None, None)   # no upstream contract.yml; snapshot used
        cc.latest_release = lambda slug: None             # no newer release
        cc.release_lag = lambda slug, tag: None

    def tearDown(self):
        (cc.fetch, cc.latest_release, cc.release_lag, ic.check_images, sys.argv) = self._saved

    def run_main(self, *argv, images=None):
        """Run main() with the image check answering `images`; returns (status, output)."""
        if images is not None:
            ic.check_images = images
        sys.argv = ["check_contracts.py", *argv]
        out, err = io.StringIO(), io.StringIO()
        with redirect_stdout(out), redirect_stderr(err):
            status = cc.main()
        return status, out.getvalue() + err.getvalue()

    # --- the finding that started this: unverified is not verified --------------------------
    def test_images_that_reached_no_verdict_fail_the_run(self):
        status, output = self.run_main(
            "--online", "--fail-on-image-drift",
            images=lambda *a: ([], ["ovos-docker: not verified - the registry could not be reached"],
                               {("ovos-docker", "testing"): (0, 28)}))
        self.assertEqual(status, 1, output)
        self.assertIn("28 of 28", output)
        self.assertIn("reached no verdict", output)

    def test_a_fully_verified_run_passes(self):
        status, output = self.run_main(
            "--online", "--fail-on-image-drift",
            images=lambda *a: ([], [], {("ovos-docker", "testing"): (28, 28),
                                        ("hivemind-docker", "testing"): (2, 2)}))
        self.assertEqual(status, 0, output)
        self.assertIn("images checked: ovos-docker@testing 28/28", output)

    def test_a_partially_verified_run_fails_and_says_by_how_much(self):
        status, output = self.run_main(
            "--online", "--fail-on-image-drift",
            images=lambda *a: ([], [], {("ovos-docker", "testing"): (26, 28)}))
        self.assertEqual(status, 1, output)
        self.assertIn("2 of 28", output)

    def test_a_repository_with_no_images_checked_at_all_fails(self):
        """(0, 0) is what a repository that was never reached looks like. It is not success."""
        status, output = self.run_main(
            "--online", "--fail-on-image-drift",
            images=lambda *a: ([], [], {("hivemind-docker", "testing"): (0, 0)}))
        self.assertEqual(status, 1, output)
        self.assertIn("not checked", output)

    def test_a_crash_in_the_image_check_is_reported_not_swallowed(self):
        def boom(*a):
            raise RuntimeError("buildx exploded")
        status, output = self.run_main("--online", "--fail-on-image-drift", images=boom)
        self.assertEqual(status, 1, output)
        self.assertIn("failed to run", output)
        self.assertIn("buildx exploded", output)

    # --- the deliberate separation, which must stay deliberate -------------------------------
    def test_image_drift_is_a_note_until_the_flag_asks_for_a_failure(self):
        """Drift depends on a registry and on someone else's rebuild schedule, so the pull
        request check must not go red for it. Only the scheduled job passes the flag."""
        status, output = self.run_main(
            "--online",
            images=lambda *a: (["ovos-docker: an image disagrees with the pinned compose"], [],
                               {("ovos-docker", "testing"): (0, 28)}))
        self.assertEqual(status, 0, output)
        self.assertIn("note:", output)

    def test_the_offline_run_makes_no_claim_about_images(self):
        def never(*a):
            raise AssertionError("the offline run must not reach a registry")
        status, output = self.run_main(images=never)
        self.assertEqual(status, 0, output)
        self.assertNotIn("images checked", output)



class FactsFloor(unittest.TestCase):
    """A checker holding no facts finds no problems.

    Every fact is pulled out of a file by regular expression. Indenting these defaults under a
    key - an ordinary Ansible refactor - makes every pattern match nothing, and before this
    floor existed the run printed "contracts satisfied" having compared nothing at all. A
    missing file raises, which is loud. A file that no longer matches does not.
    """

    def facts(self, **overrides):
        base = {
            "compose_files": {"ovos-docker": {"docker-compose.yml"},
                              "hivemind-docker": {"docker-compose.satellite.yml"}},
            "container_names": {"ovos_cli"},
            "provided_env": {"TZ"},
            "pins": {"ovos-docker": "v2.1.0", "hivemind-docker": "v2.1.2"},
            "channel": "testing",
            "slugs": {"ovos-docker": "OpenVoiceOS/ovos-docker",
                      "hivemind-docker": "JarbasHiveMind/hivemind-docker"},
        }
        base.update(overrides)
        return base

    def test_the_real_repository_passes_the_floor(self):
        """A floor that fires on the repository as it stands is an alarm, not a check."""
        self.assertEqual(cc.check_facts(cc.installer_facts()), [])

    def test_a_populated_set_of_facts_passes(self):
        self.assertEqual(cc.check_facts(self.facts()), [])

    def test_no_compose_files_is_a_violation_per_repository(self):
        problems = cc.check_facts(self.facts(compose_files={"ovos-docker": set(),
                                                            "hivemind-docker": set()}))
        self.assertEqual(len([p for p in problems if "no compose file variables" in p]), 2)

    def test_no_container_names_is_a_violation(self):
        problems = cc.check_facts(self.facts(container_names=set()))
        self.assertTrue(any("no container names matched" in p for p in problems), problems)

    def test_no_environment_variables_is_a_violation(self):
        """Empty means every variable upstream requires reads as already supplied."""
        problems = cc.check_facts(self.facts(provided_env=set()))
        self.assertTrue(any("would read as supplied" in p for p in problems), problems)

    def test_the_floor_is_wired_into_the_run(self):
        """Testing the guard is not the same as proving it is called.

        This drives main() with facts whose patterns matched nothing, the state an upstream
        refactor produces. Before the floor existed it printed "contracts satisfied" and
        returned 0.
        """
        saved = (cc.installer_facts, cc.fetch, cc.latest_release, cc.release_lag, sys.argv)
        cc.installer_facts = lambda: self.facts(
            compose_files={"ovos-docker": set(), "hivemind-docker": set()},
            container_names=set(), provided_env=set())
        cc.fetch = lambda slug, ref, path: (None, None)
        cc.latest_release = lambda slug: None
        cc.release_lag = lambda slug, tag: None
        sys.argv = ["check_contracts.py"]
        try:
            out, err = io.StringIO(), io.StringIO()
            with redirect_stdout(out), redirect_stderr(err):
                status = cc.main()
        finally:
            (cc.installer_facts, cc.fetch, cc.latest_release, cc.release_lag, sys.argv) = saved
        output = out.getvalue() + err.getvalue()
        self.assertEqual(status, 1, output)
        self.assertIn("nothing about this repository was checked", output)
        self.assertNotIn("contracts satisfied", output)

    def test_a_missing_pin_or_url_is_a_violation(self):
        problems = cc.check_facts(self.facts(pins={"ovos-docker": None, "hivemind-docker": None},
                                             slugs={"ovos-docker": "", "hivemind-docker": ""}))
        self.assertEqual(len([p for p in problems if "no pin matched" in p]), 2)
        self.assertEqual(len([p for p in problems if "no repository url matched" in p]), 2)


class DependencyBumpRecognition(unittest.TestCase):
    """Release lag counts commits an install would see; a bot's digest bump is not one.

    The pattern is matched against real subject lines rather than invented ones, because the
    cost of a miss is asymmetric: a missed bump pages a human every week for nothing, and the
    alert gets muted, which costs the checks that matter.
    """

    BUMPS = [
        "chore(deps): update dependency uv to v0.12.13",
        "build(deps): bump actions/checkout from 4 to 5",
        "Update ghcr.io/astral-sh/uv Docker tag to v0.12.13",
        "Update actions/checkout digest to 08c6903",
        "chore: update smartgic/ovos-core digest to a1b2c3d",
    ]
    REAL = [
        "fix: gate fann2 behind the lgpl extra",
        "feat: add the hivemind CLI service",
        "chore: drop core-buildroot",          # a real removal, not a dependency bump
        "Update the README with the new channel names",
    ]

    def test_bot_bumps_are_recognised(self):
        for line in self.BUMPS:
            self.assertTrue(cc.DEPENDENCY_BUMP.match(line), line)

    def test_real_changes_are_not_mistaken_for_bumps(self):
        for line in self.REAL:
            self.assertFalse(cc.DEPENDENCY_BUMP.match(line), line)


if __name__ == "__main__":
    unittest.main()

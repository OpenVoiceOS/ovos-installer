#!/usr/bin/env python3
"""Check this installer against the contracts published by the repositories it clones.

The containers method does not build anything: it clones ovos-docker and hivemind-docker at a
pinned ref and runs the compose files out of them. Four things are therefore an interface between
those repositories and this one, and all four have broken an install:

  compose file names   named exactly here; a rename upstream fails the install
  container names      docker_container_exec targets them by name; a rename fails late, after the
                       stack is already up and pulled
  environment          every variable the compose reads must come from env.j2 - or, for a variable
                       with an inline default, must come from env.j2 anyway when the installer is
                       the one that owns the value
  images               the compose is pinned by tag, the images move with a channel tag, so a
                       published image can be older than the compose that expects it - or newer
                       and expecting something the pinned compose does not provide

The third is the one that stays quiet. A compose file that starts reading HIVEMIND_SITEID keeps
working: it just uses the literal string "default" instead of the site id collected here. Nothing
fails, and every satellite reports the wrong site. That is why a contract marks such a variable
`owner: installer` and why this refuses to treat "has a default" as "nobody needs to set it".

Offline by default, against the snapshots in tests/contracts/, so this runs in any pull request.
--online re-fetches them at the pinned refs and reports a pin that has fallen behind a release.
The image half is NOT checked here: see scripts/image_coherence.py, which --online calls.
"""
import argparse
import re
import subprocess
import tempfile
import sys
import urllib.error
import urllib.request
from pathlib import Path

import yaml

sys.path.insert(0, str(Path(__file__).resolve().parent))
import image_coherence  # noqa: E402  (same directory, not a package)

DEPENDENCY_BUMP = re.compile(
    r"^(chore\(deps\)|build\(deps\)|Update .+ to v|Update .+ digest to|chore: update .+ digest)",
    re.I)

# A gh call that hangs is a gh call that failed: both leave the release lag unknown, and both
# are already reported as such. Without this the only ceiling is the job's own timeout, which
# reports nothing at all.
GH_TIMEOUT = 120  # seconds

LAST_GH_ERROR: list = []  # why a gh lookup came back empty, if it did

ROOT = Path(__file__).resolve().parent.parent
CONTAINERS = ROOT / "ansible/roles/ovos_containers/defaults/main.yml"
INSTALLER = ROOT / "ansible/roles/ovos_installer/defaults/main.yml"
ENV_TEMPLATE = ROOT / "ansible/roles/ovos_containers/templates/docker/env.j2"
SNAPSHOTS = ROOT / "tests/contracts"

# The satellite profile is the only one that runs out of hivemind-docker; everything else comes
# from ovos-docker. ovos_containers_composition_directory switches on exactly that condition.
HIVEMIND_COMPOSE_VARS = {"ovos_containers_compose_file_satellite"}

REPOS = {
    "ovos-docker": "JarbasHiveMind/ovos-docker",  # corrected below from the installer defaults
    "hivemind-docker": "JarbasHiveMind/hivemind-docker",
}


def installer_facts() -> dict:
    containers = CONTAINERS.read_text()
    installer = INSTALLER.read_text()

    compose = dict(re.findall(r"^(ovos_containers_compose_file_[a-z_]+):\s*(\S+)$", containers, re.M))
    containers_named = dict(re.findall(r"^(ovos_containers_container_[a-z_]+):\s*(\S+)$", containers, re.M))
    pins = dict(re.findall(r"^ovos_installer_(ovos|hivemind)_docker_repo_branch:\s*(\S+)$", installer, re.M))
    channel = re.search(r"^ovos_installer_channel:\s*[\"']?([A-Za-z0-9._-]+)", installer, re.M)
    urls = dict(re.findall(r"^ovos_installer_(ovos|hivemind)_docker_repo_url:\s*(\S+)$", installer, re.M))

    files = {"hivemind-docker": set(), "ovos-docker": set()}
    for var, name in compose.items():
        target = "hivemind-docker" if var in HIVEMIND_COMPOSE_VARS else "ovos-docker"
        files[target].add(name)

    return {
        "compose_files": files,
        "container_names": set(containers_named.values()),
        "provided_env": set(re.findall(r"^([A-Z][A-Z0-9_]*)=", ENV_TEMPLATE.read_text(), re.M)),
        "pins": {"ovos-docker": pins.get("ovos"), "hivemind-docker": pins.get("hivemind")},
        "channel": channel.group(1) if channel else "testing",
        "slugs": {k: re.sub(r"^https://github\.com/|\.git$", "", v)
                  for k, v in {"ovos-docker": urls.get("ovos", ""),
                               "hivemind-docker": urls.get("hivemind", "")}.items()},
    }


def check_facts(facts: dict) -> list:
    """Assert the facts exist at all, before anything is concluded from them.

    Every fact above is pulled out of a file with a regular expression, and a checker holding no
    facts finds no problems: indent these defaults under a key, rename a variable prefix, move
    them to another file, and each pattern quietly matches nothing while the run reports
    "contracts satisfied". A missing file raises, which is loud; a file that no longer matches
    does not, which is not. Only things that cannot legitimately be empty are asserted here.
    """
    problems = []
    for repo in ("ovos-docker", "hivemind-docker"):
        if not facts["compose_files"].get(repo):
            problems.append(f"{repo}: no compose file variables matched in "
                            f"{CONTAINERS.relative_to(ROOT)} - nothing about this repository was "
                            f"checked, so its contract was neither satisfied nor tested")
        if not facts["pins"].get(repo):
            problems.append(f"{repo}: no pin matched in {INSTALLER.relative_to(ROOT)}")
        if not facts["slugs"].get(repo):
            problems.append(f"{repo}: no repository url matched in {INSTALLER.relative_to(ROOT)}")
    if not facts["container_names"]:
        problems.append(f"no container names matched in {CONTAINERS.relative_to(ROOT)} - the "
                        f"rename that this check exists to catch would now pass silently")
    if not facts["provided_env"]:
        problems.append(f"no variables matched in {ENV_TEMPLATE.relative_to(ROOT)} - every "
                        f"variable upstream requires would read as supplied")
    return problems


def check(repo: str, contract: dict, facts: dict) -> list:
    problems = []
    wanted_files = facts["compose_files"][repo]
    declared_files = set(contract.get("compose_files") or [])

    for name in sorted(wanted_files - declared_files):
        problems.append(f"{repo}: compose file {name} is used here but not declared by the contract")

    # Only the files this installer actually runs matter; a satellite install must not be asked
    # for variables that only the matrix-bot compose reads.
    used = wanted_files & declared_files

    for variable, spec in sorted((contract.get("env") or {}).items()):
        if not (set(spec.get("compose_files") or []) & used):
            continue
        if variable in facts["provided_env"]:
            continue
        if spec.get("required"):
            problems.append(f"{repo}: {variable} is required by {', '.join(sorted(set(spec['compose_files']) & used))} "
                            f"and is not set in env.j2")
        elif spec.get("owner") == "installer":
            problems.append(f"{repo}: {variable} is owned by the installer but is not set in env.j2 - "
                            f"the compose has a default, so this fails silently rather than loudly")
    return problems


def check_containers(contracts: dict, facts: dict) -> list:
    """Every container this installer execs into must be declared by some contract.

    This has to look at both contracts at once. Asking one repository whether it declares a
    name and skipping the ones it does not know cannot see a rename: the old name simply
    stops appearing, the check treats it as "belongs to the other repository", and stays
    quiet - while the install still fails late with "Could not find container", which is the
    exact failure this exists to prevent.
    """
    problems = []
    reachable, declared_anywhere = set(), set()

    for repo, contract in contracts.items():
        used = facts["compose_files"][repo] & set(contract.get("compose_files") or [])
        for compose_file, services in (contract.get("services") or {}).items():
            declared_anywhere |= set(services.values())
            if compose_file in used:
                reachable |= set(services.values())

    for name in sorted(facts["container_names"] - reachable):
        if name in declared_anywhere:
            problems.append(f"container {name} is declared upstream but is in no compose file "
                            f"this installer runs")
        else:
            problems.append(f"container {name} is referenced here but no contract declares it - "
                            f"renamed or removed upstream")
    return problems


def fetch(slug: str, ref: str, path: str) -> tuple[str | None, str | None]:
    """Return (content, error).

    (content, None)  the file was fetched
    (None, None)     upstream genuinely does not publish it yet - a 404
    (None, reason)   we could not tell: DNS, a 500, a proxy. Reporting that as "not
                     published" is how a scheduled run verifies nothing and still exits 0.
    """
    url = f"https://raw.githubusercontent.com/{slug}/{ref}/{path}"
    try:
        with urllib.request.urlopen(url, timeout=30) as response:
            return response.read().decode(), None
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return None, None
        return None, f"HTTP {error.code}"
    except Exception as error:
        return None, f"{type(error).__name__}: {error}"


def release_lag(slug: str, tag: str) -> tuple[int, str] | None:
    """How far the newest release trails the branch it is cut from.

    Pinning a release is what makes an install reproducible, but a fix only reaches anyone once a
    release carries it. Comparing the pin against the newest release cannot see this: both can say
    v2.0.2 while ten days of fixes sit unreleased on the default branch, which is exactly how the
    fann2 gating and the intent-engine assertion failed to reach a single install.
    """
    try:
        branch = subprocess.run(["gh", "repo", "view", slug, "--json", "defaultBranchRef",
                                 "-q", ".defaultBranchRef.name"],
                                capture_output=True, text=True, check=True,
                                timeout=GH_TIMEOUT).stdout.strip()
        out = subprocess.run(["gh", "api", f"repos/{slug}/compare/{tag}...{branch}",
                              # single-parent only: a merge commit repeats what it merges,
                              # and counting it makes a lone dependency bump look substantive
                              "-q", ".commits[] | select(.parents | length == 1) "
                                    "| .commit.message | split(\"\\n\")[0]"],
                             capture_output=True, text=True, check=True, timeout=GH_TIMEOUT)
        # Only unreleased *fixes* are worth a release. Renovate merges dependency bumps
        # continuously, and failing a weekly job for those trains people to ignore it -
        # at which point the alert no longer works for the case it exists for.
        subjects = [line for line in out.stdout.splitlines() if line.strip()]
        substantive = [line for line in subjects
                       if not DEPENDENCY_BUMP.match(line.strip())]
        return len(substantive), branch
    except Exception as error:
        LAST_GH_ERROR.append(f"{type(error).__name__}: {error}")
        return None


def latest_release(slug: str) -> str | None:
    try:
        out = subprocess.run(["gh", "release", "view", "--repo", slug, "--json", "tagName", "-q", ".tagName"],
                             capture_output=True, text=True, check=True, timeout=GH_TIMEOUT)
        return out.stdout.strip() or None
    except Exception as error:
        LAST_GH_ERROR.append(f"{type(error).__name__}: {error}")
        return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--online", action="store_true",
                        help="re-fetch the contracts at the pinned refs and check pin freshness")
    parser.add_argument("--fail-on-image-drift", action="store_true",
                        help="treat an image that disagrees with the pinned compose as a failure. "
                             "Separate from --fail-on-stale because it depends on a registry and "
                             "on the producer's rebuild schedule, so it can go red for reasons a "
                             "pin bump cannot fix.")
    parser.add_argument("--fail-on-stale", action="store_true",
                        help="treat a pin behind the latest release as a failure. A scheduled run "
                             "that exits 0 tells nobody anything, so the job that watches for "
                             "this uses it; the pull request check does not.")
    args = parser.parse_args()

    facts = installer_facts()
    problems, notes, contracts = [], [], {}
    pending_lag = {}

    problems.extend(check_facts(facts))

    for repo in ("ovos-docker", "hivemind-docker"):
        snapshot = SNAPSHOTS / f"{repo}.yml"
        if not snapshot.exists():
            problems.append(f"{repo}: no contract snapshot at {snapshot.relative_to(ROOT)}")
            continue
        contract = yaml.safe_load(snapshot.read_text())
        contracts[repo] = contract

        if args.online:
            slug, ref = facts["slugs"][repo], facts["pins"][repo]
            live, fetch_error = fetch(slug, ref, "contract.yml")
            if fetch_error:
                # not the same as "upstream has none": we simply did not find out
                message = (f"{repo}: could not read contract.yml at {ref} ({fetch_error}) - "
                           f"nothing upstream was verified")
                (problems if args.fail_on_stale else notes).append(message)
            elif live is None:
                notes.append(f"{repo}: {ref} publishes no contract.yml yet; using the snapshot")
            elif yaml.safe_load(live) != contract:
                problems.append(f"{repo}: the snapshot differs from contract.yml at {ref} - "
                                f"refresh tests/contracts/{repo}.yml")

            del LAST_GH_ERROR[:]
            newest = latest_release(slug)
            if newest and newest != ref:
                message = f"{repo}: pinned {ref}, latest release is {newest}"
                (problems if args.fail_on_stale else notes).append(message)

            lag = release_lag(slug, newest or ref) if newest else None
            if lag and lag[0]:
                pending_lag[repo] = (newest or ref, lag[0], lag[1])
            elif LAST_GH_ERROR:
                # gh missing, unauthenticated or rate-limited looks exactly like "nothing is
                # behind" unless it is reported, and then the run passes having checked nothing
                message = (f"{repo}: could not check release freshness ({LAST_GH_ERROR[0]}) - "
                           f"the pin and the release lag were not verified")
                (problems if args.fail_on_stale else notes).append(message)

        problems.extend(check(repo, contract, facts))

    problems.extend(check_containers(contracts, facts))

    if args.online:
        # Clones go to a temporary directory, never inside the repository: a checkout of another
        # project under ROOT gets picked up by this repository's own linters and tests.
        with tempfile.TemporaryDirectory(prefix="ovos-contract-pins-") as cache:
            try:
                image_problems, image_notes, coverage = image_coherence.check_images(
                    contracts, facts, Path(cache), facts["channel"])
            except Exception as error:  # a crash here must be reported, not thrown away
                image_problems = [f"the image check failed to run: "
                                  f"{type(error).__name__}: {str(error)[:140]}"]
                image_notes, coverage = [], {}

            # A release trailing its branch is only worth failing over when the commits in
            # between are ones an install can observe. Asked with the producer's own selector,
            # the same way the image half asks it.
            for repo, (release, behind, branch) in sorted(pending_lag.items()):
                clone = Path(cache) / (facts["slugs"][repo] or "").replace("/", "_")
                if not clone.exists():
                    (problems if args.fail_on_stale else notes).append(
                        f"{repo}: {release} is behind {branch} by {behind} change(s) and whether "
                        f"an install sees them could not be checked - no clone at {release}")
                    continue
                affects, detail = image_coherence.unreleased_impact(
                    clone, release, branch, facts["compose_files"][repo])
                if affects is None:
                    (problems if args.fail_on_stale else notes).append(
                        f"{repo}: {release} is behind {branch} by {behind} change(s) and their "
                        f"impact could not be determined ({detail})")
                elif affects:
                    message = (f"{repo}: {release} is behind {branch} by {behind} change(s) an "
                               f"install would see ({detail}) - they are in no release")
                    (problems if args.fail_on_stale else notes).append(message)
                else:
                    notes.append(f"{repo}: {release} is behind {branch} by {behind} change(s), "
                                 f"but {detail} - no release needed for an install's sake")
        # Printed unconditionally, and asserted: a printed count nobody checks is decoration.
        # Without this every "could not tell" outcome lands in notes, which can never fail the
        # job, so a run that verified nothing ends green - the exact shape this check exists to
        # catch elsewhere.
        for (repo, tag), (resolved, total) in sorted(coverage.items()):
            print(f"images checked: {repo}@{tag} {resolved}/{total}"
                  + ("" if total else " (not checked)"))
            if resolved < total or not total:
                missing = (total - resolved) if total else "all"
                image_problems.append(
                    f"{repo}@{tag}: {missing} of {total or 'its'} images reached no verdict - "
                    f"the run did not establish that they match the pinned compose")
        notes.extend(image_notes)
        (problems if args.fail_on_image_drift else notes).extend(image_problems)

    for note in notes:
        print(f"note: {note}")
    sys.stdout.flush()  # keep notes above the violations in a CI log

    if problems:
        print("\ncontract violations:", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        return 1

    pinned = ", ".join("{0} {1}".format(repo, facts["pins"][repo]) for repo in facts["pins"])
    print("contracts satisfied: " + pinned)
    return 0


if __name__ == "__main__":
    sys.exit(main())

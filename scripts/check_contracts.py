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
  images               the compose is pinned by tag, the images move with a channel tag, so an
                       image can be older than the compose that expects it

The third is the one that stays quiet. A compose file that starts reading HIVEMIND_SITEID keeps
working: it just uses the literal string "default" instead of the site id collected here. Nothing
fails, and every satellite reports the wrong site. That is why a contract marks such a variable
`owner: installer` and why this refuses to treat "has a default" as "nobody needs to set it".

Offline by default, against the snapshots in tests/contracts/, so this runs in any pull request.
--online re-fetches them at the pinned refs, reports a pin that has fallen behind a release, and
checks that the published images are not older than the compose pinned here.
"""
import argparse
import json
import re
import subprocess
import sys
import urllib.error
import urllib.request
from pathlib import Path

import yaml

DEPENDENCY_BUMP = re.compile(r"^(chore\(deps\)|Update .+ to v|build\(deps\)|chore: update .+ digest)", re.I)

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
        "slugs": {k: re.sub(r"^https://github\.com/|\.git$", "", v)
                  for k, v in {"ovos-docker": urls.get("ovos", ""),
                               "hivemind-docker": urls.get("hivemind", "")}.items()},
    }


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
                                capture_output=True, text=True, check=True).stdout.strip()
        out = subprocess.run(["gh", "api", f"repos/{slug}/compare/{tag}...{branch}",
                              # single-parent only: a merge commit repeats what it merges,
                              # and counting it makes a lone dependency bump look substantive
                              "-q", ".commits[] | select(.parents | length == 1) "
                                    "| .commit.message | split(\"\\n\")[0]"],
                             capture_output=True, text=True, check=True)
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
                             capture_output=True, text=True, check=True)
        return out.stdout.strip() or None
    except Exception as error:
        LAST_GH_ERROR.append(f"{type(error).__name__}: {error}")
        return None


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--online", action="store_true",
                        help="re-fetch the contracts at the pinned refs and check pin freshness")
    parser.add_argument("--fail-on-stale", action="store_true",
                        help="treat a pin behind the latest release as a failure. A scheduled run "
                             "that exits 0 tells nobody anything, so the job that watches for "
                             "this uses it; the pull request check does not.")
    args = parser.parse_args()

    facts = installer_facts()
    problems, notes, contracts = [], [], {}

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
                behind, branch = lag
                message = (f"{repo}: {newest or ref} is behind {branch} by {behind} "
                           f"change(s) that are not dependency bumps - those fixes are in no "
                           f"release, so no install has them")
                (problems if args.fail_on_stale else notes).append(message)
            elif LAST_GH_ERROR:
                # gh missing, unauthenticated or rate-limited looks exactly like "nothing is
                # behind" unless it is reported, and then the run passes having checked nothing
                message = (f"{repo}: could not check release freshness ({LAST_GH_ERROR[0]}) - "
                           f"the pin and the release lag were not verified")
                (problems if args.fail_on_stale else notes).append(message)

        problems.extend(check(repo, contract, facts))

    problems.extend(check_containers(contracts, facts))

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

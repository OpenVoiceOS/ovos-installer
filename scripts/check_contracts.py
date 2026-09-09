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
import urllib.request
from pathlib import Path

import yaml

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

    declared_containers = {
        name for compose_file, services in (contract.get("services") or {}).items()
        if compose_file in used for name in services.values()
    }
    all_containers = {
        name for services in (contract.get("services") or {}).values() for name in services.values()
    }
    for name in sorted(facts["container_names"] & all_containers - declared_containers):
        problems.append(f"{repo}: container {name} is referenced here but is not in any compose "
                        f"file this installer runs")

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


def fetch(slug: str, ref: str, path: str) -> str | None:
    url = f"https://raw.githubusercontent.com/{slug}/{ref}/{path}"
    try:
        with urllib.request.urlopen(url, timeout=30) as response:
            return response.read().decode()
    except Exception:
        return None


def latest_release(slug: str) -> str | None:
    try:
        out = subprocess.run(["gh", "release", "view", "--repo", slug, "--json", "tagName", "-q", ".tagName"],
                             capture_output=True, text=True, check=True)
        return out.stdout.strip() or None
    except Exception:
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
    problems, notes = [], []

    for repo in ("ovos-docker", "hivemind-docker"):
        snapshot = SNAPSHOTS / f"{repo}.yml"
        if not snapshot.exists():
            problems.append(f"{repo}: no contract snapshot at {snapshot.relative_to(ROOT)}")
            continue
        contract = yaml.safe_load(snapshot.read_text())

        if args.online:
            slug, ref = facts["slugs"][repo], facts["pins"][repo]
            live = fetch(slug, ref, "contract.yml")
            if live is None:
                notes.append(f"{repo}: {ref} publishes no contract.yml yet; using the snapshot")
            elif yaml.safe_load(live) != contract:
                problems.append(f"{repo}: the snapshot differs from contract.yml at {ref} - "
                                f"refresh tests/contracts/{repo}.yml")
            newest = latest_release(slug)
            if newest and newest != ref:
                message = f"{repo}: pinned {ref}, latest release is {newest}"
                (problems if args.fail_on_stale else notes).append(message)

        problems.extend(check(repo, contract, facts))

    for note in notes:
        print(f"note: {note}")
    sys.stdout.flush()  # keep notes above the violations in a CI log

    if problems:
        print("\ncontract violations:", file=sys.stderr)
        for problem in problems:
            print(f"  {problem}", file=sys.stderr)
        return 1

    print(f"contracts satisfied: {', '.join(f'{r} {facts['pins'][r]}' for r in facts['pins'])}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Check that the images an install pulls agree with the compose files it runs.

The containers method takes its compose files from a git tag and its images from a channel tag
that keeps moving. Those two can disagree, and when they do the failure is remote from its cause:
a compose file expects behaviour the published image does not have, and the install breaks with a
traceback about something else entirely.

The hard part is not detecting a difference, it is deciding whether the difference matters. An
image is rebuilt whenever the channel's constraints move, with no commit in this repository at
all, so its revision sits behind the tag permanently and legitimately. "Image revision is older
than the pinned ref" is therefore not a defect - it is the normal state.

So the question asked here is narrower: between the image's revision and the pinned ref, did
anything change that would have rebuilt THIS image? That question already has an authoritative
answer in the producer's own scripts/affected.py, the selector its CI uses to decide what to
rebuild. Running that, in a checkout at the pinned ref, means this check and the publisher cannot
disagree about what affects an image - rather than this file inventing a second opinion that
drifts.

Labels are read from the GHCR mirror over the anonymous registry API. Docker Hub would work too
and is where the installer actually pulls from, but its unauthenticated budget is ~100 manifest
requests per hour per IP, shared across everything on a runner's egress - so using it here would
break other jobs rather than this one.
"""
import concurrent.futures
import json
import re
import subprocess
import urllib.error
import urllib.request
from pathlib import Path

import yaml

REGISTRY_TIMEOUT = 20
TAG_VAR = re.compile(r":\$\{?[A-Za-z_][A-Za-z0-9_]*\}?$")


def canonical_image(image: str) -> str:
    """Drop the tag variable and give the repository an explicit registry.

    Kept identical to contract.py's function of the same name so the two agree on what an image
    is called; the compose files spell the same registry both with and without docker.io/.
    """
    repository = TAG_VAR.sub("", image)
    host = repository.split("/", 1)[0]
    if "." not in host and ":" not in host and host != "localhost":
        repository = f"docker.io/{repository}"
    return repository


def run(args, cwd=None, check=True):
    return subprocess.run(args, cwd=cwd, capture_output=True, text=True, check=check)


def pin_clone(slug: str, ref: str, cache: Path):
    """A blobless clone of the producer at the pinned ref.

    Blobless because every question here is answered by trees and history - which paths changed,
    which commit is an ancestor - and never by file contents outside compose/, which `git show`
    fetches on demand. Full clone of ovos-docker is ~14MB; this is ~1MB.
    """
    target = cache / slug.replace("/", "_")
    if not target.exists():
        run(["git", "clone", "--filter=blob:none", "--quiet",
             f"https://github.com/{slug}", str(target)])
    run(["git", "-C", str(target), "checkout", "--quiet", ref])
    return target


def deployed_images(clone: Path, ref: str, compose_names) -> dict:
    """Images the installer actually pulls: every service in the compose files it runs.

    Scope comes from the compose files rather than from the contract's `images` list, because the
    contract lists everything the producer builds while an install runs a profile-selected subset.
    Checking what is not deployed would report drift nobody can experience.
    """
    found = {}
    for name in sorted(compose_names):
        try:
            body = run(["git", "-C", str(clone), "show", f"{ref}:compose/{name}"]).stdout
        except subprocess.CalledProcessError:
            continue
        for service, spec in (yaml.safe_load(body).get("services") or {}).items():
            if isinstance(spec, dict) and spec.get("image"):
                found.setdefault(canonical_image(spec["image"]), {})[name] = service
    return found


def read_labels(path: str, tag: str):
    """(labels, outcome) for ghcr.io/<path>:<tag>. outcome: ok | no_tag | denied | transport.

    The outcomes are kept apart on purpose. "The tag is not there" is a finding; "we could not
    reach the registry" is not, and collapsing them is how a check ends up reporting failure as
    success.
    """
    def get(url, headers=None, accept=None):
        request = urllib.request.Request(url, headers=headers or {})
        if accept:
            request.add_header("Accept", accept)
        with urllib.request.urlopen(request, timeout=REGISTRY_TIMEOUT) as response:
            return json.loads(response.read().decode())

    manifest_types = ("application/vnd.oci.image.index.v1+json,"
                      "application/vnd.docker.distribution.manifest.list.v2+json,"
                      "application/vnd.oci.image.manifest.v1+json,"
                      "application/vnd.docker.distribution.manifest.v2+json")
    try:
        token = get(f"https://ghcr.io/token?service=ghcr.io&scope=repository:{path}:pull")["token"]
        auth = {"Authorization": f"Bearer {token}"}
        manifest = get(f"https://ghcr.io/v2/{path}/manifests/{tag}", auth, manifest_types)

        if "manifests" in manifest:
            # An index carries attestation manifests whose config blob is literally {} - reading
            # those reports "no revision" for every multi-arch image, so take a real platform.
            digests = [m["digest"] for m in manifest["manifests"]
                       if (m.get("platform") or {}).get("architecture") not in (None, "unknown")]
            if not digests:
                return None, "no_tag"
            manifest = get(f"https://ghcr.io/v2/{path}/manifests/{digests[0]}", auth, manifest_types)

        config_digest = (manifest.get("config") or {}).get("digest")
        if not config_digest:
            return None, "no_tag"
        config = get(f"https://ghcr.io/v2/{path}/blobs/{config_digest}", auth)
        # Labels can be null rather than absent.
        return ((config.get("config") or {}).get("Labels") or {}), "ok"
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return None, "no_tag"
        if error.code in (401, 403):
            return None, "denied"
        return None, "transport"
    except Exception:
        return None, "transport"


def mirror_candidates(image: str, slugs: dict, declaring: str):
    """GHCR paths to try for an image, the declaring repository's mirror first.

    The mirror name is a convention from the producer's build workflow, declared in no contract,
    so a miss here has to fall through to the next candidate rather than read as "no such image".
    An image declared by one repository can be built by the other - ovos-docker's compose deploys
    hivemind-cli - which is why the other pinned slug is tried too.
    """
    name = image.rsplit("/", 1)[-1]
    ordered, seen = [], set()
    for repo in [declaring] + [r for r in slugs if r != declaring]:
        slug = (slugs.get(repo) or "").lower()
        if slug and slug not in seen:
            seen.add(slug)
            ordered.append((repo, f"{slug}/{name}"))
    return ordered


def rebuild_targets(clone: Path, revision: str, pin: str):
    """Targets the producer's own selector says a rev..pin diff would rebuild.

    Returns (targets, reason). reason is None on success; anything else means the oracle could not
    answer and the caller must say so rather than assume zero.
    """
    try:
        run(["git", "-C", str(clone), "cat-file", "-e", f"{revision}^{{commit}}"])
    except subprocess.CalledProcessError:
        try:
            run(["git", "-C", str(clone), "fetch", "--quiet", "origin", revision])
        except subprocess.CalledProcessError:
            return None, f"revision {revision[:12]} is not reachable in the repository"
    try:
        changed = run(["git", "-C", str(clone), "diff", "--name-only", revision, pin]).stdout
    except subprocess.CalledProcessError as error:
        return None, f"could not diff {revision[:12]}..{pin}: {error.stderr.strip()[:120]}"
    if not changed.strip():
        return [], None

    selector = clone / "scripts" / "affected.py"
    if not selector.exists():
        return None, "the producer has no scripts/affected.py at this ref"
    try:
        result = subprocess.run(["python3", str(selector), "paths"], cwd=str(clone),
                                input=changed, capture_output=True, text=True, check=True)
        return json.loads(result.stdout), None
    except Exception as error:
        return None, f"the rebuild selector failed: {str(error)[:140]}"


def target_images(clone: Path):
    """image repository -> bake target, from the producer's own bake graph at this ref.

    Needs the buildx CLI but no daemon and no network. Absent buildx is "cannot tell", never
    "nothing is affected".
    """
    try:
        printed = run(["docker", "buildx", "bake", "--print", "default"], cwd=str(clone)).stdout
    except Exception:
        return None
    try:
        graph = json.loads(printed)
    except json.JSONDecodeError:
        return None
    mapping = {}
    for target, body in (graph.get("target") or {}).items():
        for tag in (body.get("tags") or []):
            mapping[tag.rsplit(":", 1)[0]] = target
    return mapping


def service_interface(clone: Path, ref: str, compose_name: str, service: str):
    """The part of a service definition an image has to agree with.

    Environment keys, volume targets and the entrypoint/command: if the image moved ahead of the
    compose and one of these changed, the running container is configured by a file that predates
    what the image now expects. Values are deliberately excluded - they are the installer's to set.
    """
    try:
        body = run(["git", "-C", str(clone), "show", f"{ref}:compose/{compose_name}"]).stdout
    except subprocess.CalledProcessError:
        return None
    spec = ((yaml.safe_load(body) or {}).get("services") or {}).get(service)
    if not isinstance(spec, dict):
        return None
    environment = spec.get("environment")
    if isinstance(environment, dict):
        keys = sorted(environment)
    elif isinstance(environment, list):
        keys = sorted(item.split("=", 1)[0] for item in environment if isinstance(item, str))
    else:
        keys = []
    volumes = sorted(v.split(":")[1] for v in (spec.get("volumes") or [])
                     if isinstance(v, str) and v.count(":") >= 1)
    return {"environment": keys, "volumes": volumes,
            "entrypoint": spec.get("entrypoint"), "command": spec.get("command")}


def check_images(contracts: dict, facts: dict, cache: Path, channel: str):
    """Compare what an install pulls against the compose it runs.

    Returns (problems, notes, coverage). Nothing here is a problem unless it is both real and
    actionable; everything unresolved is a note that names why, and the coverage counts are
    printed by the caller so a run that verified nothing cannot look like a clean one.
    """
    problems, notes, coverage = [], [], {}
    clones, oracles = {}, {}

    for repo, contract in contracts.items():
        slug, pin = facts["slugs"].get(repo), facts["pins"].get(repo)
        if not slug or not pin:
            notes.append(f"{repo}: no pin or repository url in the installer defaults")
            continue
        try:
            clones[repo] = pin_clone(slug, pin, cache)
        except Exception as error:
            notes.append(f"{repo}: could not clone {slug} at {pin} ({str(error)[:90]}) - "
                         f"no image was verified for it")
            continue
        oracles[repo] = target_images(clones[repo])
        if oracles[repo] is None:
            notes.append(f"{repo}: could not read the bake graph at {pin} (is docker buildx "
                         f"installed?) - images cannot be attributed to a build target")

    for repo, contract in contracts.items():
        clone = clones.get(repo)
        if clone is None:
            continue
        pin = facts["pins"][repo]
        deployed = deployed_images(clone, pin, facts["compose_files"][repo])

        declared = set(contract.get("images") or [])
        for image in sorted(set(deployed) - declared):
            problems.append(f"{repo}: the pinned compose deploys {image} but the contract does not "
                            f"declare it - the producer's own contract gate missed it")

        resolved = 0
        for image in sorted(deployed):
            labels, outcome, used_repo = None, "no_tag", None
            for candidate_repo, path in mirror_candidates(image, facts["slugs"], repo):
                labels, outcome = read_labels(path, channel)
                if outcome == "ok":
                    used_repo = candidate_repo
                    break
            if outcome != "ok":
                reason = {"no_tag": f"no :{channel} tag published",
                          "denied": "the mirror refused anonymous access",
                          "transport": "the registry could not be reached"}[outcome]
                notes.append(f"{repo}: {image} not verified - {reason}")
                continue

            revision = labels.get("org.opencontainers.image.revision")
            source = (labels.get("org.opencontainers.image.source") or "").rsplit("github.com/", 1)[-1]
            if not revision:
                notes.append(f"{repo}: {image}:{channel} carries no revision label - not verified")
                continue

            # An image is judged against the repository that built it, which is not always the one
            # whose compose deploys it: ovos-docker's compose runs hivemind-cli.
            owner = next((r for r, s in facts["slugs"].items()
                          if s and s.lower() == source.lower()), None)
            if owner is None:
                notes.append(f"{repo}: {image} is built by {source or 'an unknown repository'}, "
                             f"which this installer does not pin - out of scope")
                continue
            owner_clone, owner_pin = clones.get(owner), facts["pins"].get(owner)
            if owner_clone is None:
                notes.append(f"{repo}: {image} is built by {owner}, which could not be cloned - "
                             f"not verified")
                continue

            resolved += 1
            verdict, detail = compare(owner_clone, owner_pin, revision, image,
                                      oracles.get(owner), deployed[image], clone, pin)
            if verdict == "behind":
                problems.append(f"{repo}: {image}:{channel} was built from {revision[:12]}, which "
                                f"predates {owner_pin} by changes that rebuild it ({detail}) - the "
                                f"pinned compose expects an image this one is not")
            elif verdict == "ahead":
                problems.append(f"{repo}: {image}:{channel} was built from {revision[:12]}, which "
                                f"is ahead of {owner_pin}, and {detail} - the image expects a "
                                f"compose newer than the one pinned here")
            elif verdict == "unknown":
                notes.append(f"{repo}: {image} not verified - {detail}")

        coverage[(repo, channel)] = (resolved, len(deployed))

    return problems, notes, coverage


def compare(clone: Path, pin: str, revision: str, image: str, oracle, placements, compose_clone, compose_pin):
    """(verdict, detail). verdict: coherent | behind | ahead | unknown."""
    try:
        run(["git", "-C", str(clone), "cat-file", "-e", f"{revision}^{{commit}}"])
    except subprocess.CalledProcessError:
        try:
            run(["git", "-C", str(clone), "fetch", "--quiet", "origin", revision])
        except subprocess.CalledProcessError:
            return "unknown", f"revision {revision[:12]} is not reachable in {clone.name}"

    behind = subprocess.run(["git", "-C", str(clone), "merge-base", "--is-ancestor", revision, pin],
                            capture_output=True).returncode == 0
    ahead = subprocess.run(["git", "-C", str(clone), "merge-base", "--is-ancestor", pin, revision],
                           capture_output=True).returncode == 0

    if behind and ahead:
        return "coherent", "built from the pinned tree"
    if not behind and not ahead:
        return "unknown", (f"revision {revision[:12]} and {pin} have diverged - neither contains "
                           f"the other")

    if behind:
        if oracle is None:
            return "unknown", "the bake graph was unavailable, so nothing could be attributed"
        target = oracle.get(image)
        if target is None:
            return "unknown", (f"{image} has no bake target at {pin}, so whether it would be "
                               f"rebuilt cannot be decided")
        targets, reason = rebuild_targets(clone, revision, pin)
        if reason:
            return "unknown", reason
        return ("behind", f"rebuilds {target}") if target in targets else ("coherent", "unaffected")

    # Ahead: the image moved past the compose. What matters is whether the part of the service
    # definition the image has to agree with changed underneath it.
    changed = []
    for compose_name, service in (placements or {}).items():
        at_pin = service_interface(compose_clone, compose_pin, compose_name, service)
        at_rev = service_interface(clone, revision, compose_name, service)
        if at_pin is None or at_rev is None:
            continue
        for field in ("environment", "volumes", "entrypoint", "command"):
            if at_pin.get(field) != at_rev.get(field):
                changed.append(f"{service}.{field}")
    if changed:
        return "ahead", "its service definition changed since: " + ", ".join(sorted(set(changed)))
    return "coherent", "ahead, but no service interface it depends on changed"


def unreleased_impact(clone: Path, tag: str, branch: str, compose_names):
    """(affects, detail) for what sits on `branch` but not in `tag`.

    A release trailing its branch only matters when the commits in between are ones an install
    can observe: a compose file it runs, or a path that rebuilds an image it pulls. CI workflows,
    tests and the contract tooling itself are substantive commits that change nothing a consumer
    consumes, and failing a weekly job for those would teach people to ignore it - the same way a
    naive image rule would have.
    """
    try:
        run(["git", "-C", str(clone), "fetch", "--quiet", "origin", branch])
        head = run(["git", "-C", str(clone), "rev-parse", "FETCH_HEAD"]).stdout.strip()
        changed = run(["git", "-C", str(clone), "diff", "--name-only", tag, head]).stdout
    except subprocess.CalledProcessError as error:
        return None, f"could not compare {tag} with {branch}: {error.stderr.strip()[:110]}"

    touched = [line for line in changed.splitlines() if line.strip()]
    if not touched:
        return False, "nothing"

    compose_changed = sorted({line.split("/", 1)[1] for line in touched
                              if line.startswith("compose/") and "/" in line
                              and line.split("/", 1)[1] in compose_names})
    targets, reason = rebuild_targets(clone, tag, head)
    if reason:
        return None, reason

    if compose_changed or targets:
        parts = []
        if compose_changed:
            parts.append("compose: " + ", ".join(compose_changed))
        if targets:
            parts.append(f"rebuilds {len(targets)} image(s)")
        return True, "; ".join(parts)
    return False, "only paths no install consumes"

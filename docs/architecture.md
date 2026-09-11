# How the installer works

For people changing the installer rather than using it.
[Back to the README](../README.md).

## Shape

Two halves:

- **A shell TUI** (`tui/`) asks the questions, and `utils/` detects the machine
  — distribution, hardware, sound and display servers, existing installs.
- **An Ansible playbook** (`ansible/`) does the work, driven by
  `ansible/site.yml` against `localhost`.

`installer.sh` is the entry point the one-liner downloads. It clones this
repository and hands over to `setup.sh`, which runs the detection, then the
TUI, then the playbook.

Because `installer.sh` clones `main` on every run, whatever is on `main` is
what users get on their next install.

## The screens

Screens live in `tui/` and are steps in a list. Each reports `next`, `back` or
`repeat` through `TUI_NAV` and returns; `tui/main.sh` walks the flow and
decides what comes next, stepping over screens a given run does not need. This
is what lets **Back** work from anywhere without screens having to know about
each other.

Their text is translated. `tui/locales/` is **generated** — edit
`translations/<locale>/strings.json` instead, and regenerate with
`scripts/sync_translations.py`. Translations come from GitLocalize, so
hand-edited locale files are overwritten.

## The playbook

A wrapper role, `ovos_installer`, orchestrates focused roles roughly in this
order:

| Role | Responsibility |
| --- | --- |
| `ovos_facts` | Shared installer facts: boot directory, NetworkManager, systemd paths |
| `ovos_timezone` | Detect and configure the system timezone |
| `ovos_config` | Configuration defaults and `mycroft.conf` generation |
| `ovos_sound` | Sound server setup, PipeWire or PulseAudio |
| `ovos_virtualenv` | Python virtual environment and package installation |
| `ovos_containers` | Docker and compose provisioning and deployment |
| `ovos_services` | Systemd units and handlers, user or system scope |
| `ovos_telemetry` | Optional telemetry submission |
| `ovos_storage_tuning` | fstab, log2ram and tmpfs tuning |
| `ovos_audio_tuning` | PipeWire and WirePlumber tuning |
| `ovos_python` | Python runtime tuning, mimalloc and environment |
| `ovos_performance_tuning` | Governor, I/O, zram, sysctl, NUMA, limits |
| `ovos_network_tuning` | Wireless power management and DNS caching |
| `ovos_finalize` | Post-install cleanup and drift notice |
| `ovos_hardware_mark1`, `ovos_hardware_mark2` | Hardware-specific, applied when that hardware is detected |

## The containers method

`ovos_containers` installs Docker, then clones another repository and runs its
compose files out of it. It builds no image and ships no compose file of its own.

| Profile | Repository | Pin | Compose run from |
| --- | --- | --- | --- |
| everything but `satellite` | `OpenVoiceOS/ovos-docker` | `ovos_installer_ovos_docker_repo_branch` | `/tmp/ovos-docker/compose` |
| `satellite` | `JarbasHiveMind/hivemind-docker` | `ovos_installer_hivemind_docker_repo_branch` | `/tmp/hivemind-docker/compose` |

Both pins are release tags, set in `ansible/roles/ovos_installer/defaults/main.yml`.
The images are not pinned with them: `templates/docker/env.j2` sets `VERSION` to
the chosen channel, a tag that keeps moving. The two halves therefore travel at
different speeds. A compose change upstream reaches nobody until the pin here is
bumped, while a rebuilt image is pulled by the next install that runs.

Four things are an interface with those repositories, and each has broken an
install: the compose file names, the container names (`docker_container_exec`
targets them by name), the environment variables the compose reads, and the
images. Environment is the quiet one - a variable carrying an inline default
leaves the stack running while it silently uses the wrong value, which is how
every satellite reported the site id `default` for a while. A contract marks
such a variable `owner: installer`, meaning this installer has to supply it even
though the compose would survive without it.

Each producer publishes a `contract.yml` declaring all four.
`scripts/check_contracts.py` checks this installer against the vendored copies
in `tests/contracts/`, offline, in every pull request.
`.github/workflows/contracts.yml` runs the half that needs a network once a
week: it re-fetches each contract at the pinned tag, reports a pin that has
fallen behind a release, and asks whether the published channel images agree
with the compose files at that pin. `scripts/image_coherence.py` answers the
last question by asking the producer's own `scripts/affected.py`, in a clone at
the pinned tag, whether anything between an image's revision and that tag would
rebuild that image - because images are also rebuilt when channel constraints
move, with no commit in the producer at all, so an image being older than the
pin is the normal state rather than a defect.

## Tests

`tests/bats/` runs under [bats](https://github.com/bats-core/bats-core). Most
of it stubs `whiptail`, which keeps it fast; `tests/bats/tui_whiptail.bats`
drives the real binary in a pseudo terminal, because the stub cannot show how
whiptail itself behaves.

The contract checkers are Python and are tested as Python: `scripts/test_*.py`
run under `unittest`, offline, against throwaway git repositories rather than
the network. `tests/bats/code_quality.bats` runs them, so they gate a pull
request like everything else. `ruff check .` runs over every Python file in
`.github/workflows/linting.yml`.

Screenshots in the README are generated by `scripts/render_screenshots.py`,
which walks the flow and renders what the terminal actually displays.

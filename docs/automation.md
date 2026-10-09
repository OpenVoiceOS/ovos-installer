Last Edit: Codex (GPT-6) - 2026-10-09 - Motive: Clarify complete-log limits, satellite redaction and interruption cleanup.

# Automation

Installing without answering questions, for scripted installs or several
devices at once. [Back to the README](../README.md).

## Scenario file

Drop a scenario file at `~/.config/ovos-installer/scenario.yaml` and the
installer reads it instead of asking. This one installs OVOS in containers on a
Raspberry Pi with the default skills:

```shell
mkdir -p ~/.config/ovos-installer
cat <<EOF > ~/.config/ovos-installer/scenario.yaml
---
uninstall: false
method: containers
channel: testing
profile: ovos
features:
  skills: true
  extra_skills: false
raspberry_pi_tuning: true
share_telemetry: true
share_usage_telemetry: true
EOF
```

Then run the installer as usual. More examples live in
[scenarios/](https://github.com/OpenVoiceOS/ovos-installer/tree/main/scenarios),
including one that runs speech recognition and the voice on a Raspberry Pi 5
([scenario-local-speech.yml](https://github.com/OpenVoiceOS/ovos-installer/blob/main/scenarios/scenario-local-speech.yml)).

## Scenario settings

| Setting | What it does |
| --- | --- |
| `uninstall` | `true` uninstalls instead of installing |
| `method` | `virtualenv` or `containers`. macOS and Mark 2 hardware: `virtualenv` only |
| `channel` | `testing` or `alpha`. macOS: `alpha` only |
| `profile` | `ovos` for a standard setup |
| `features.skills` | Install the default voice skills |
| `features.extra_skills` | Install additional community skills |
| `features.llm` | Enable the OVOS Persona LLM fallback |
| `llm.api_url` | OpenAI-compatible API base URL, required with `features.llm` |
| `llm.key` | API key for that endpoint, required with `features.llm` |
| `llm.model` | Model name to use, required with `features.llm` |
| `llm.persona` | System prompt for `ovos-persona`, required with `features.llm` |
| `speech_engine` | `public` (the default) uses community servers, which can go offline at any time. `local` runs speech on the device **with public fallback**: failed or empty recognition sends the recording to public servers, and recognition or voice synthesis uses public servers entirely if its local model cannot run. The installer reports any setup fallback. Local needs the `alpha` channel, a profile with audio (with `containers`, `ovos` or `listener`) and a Raspberry Pi 5 with 8 GB or an equivalent machine; anywhere else the installer uses `public`. This is not a fully offline mode. |
| `raspberry_pi_tuning` | Maximum-performance tuning for a Pi, including an overclocking prompt |
| `share_telemetry` | Share anonymous usage statistics — see [Telemetry](telemetry.md) |
| `share_usage_telemetry` | Share detailed usage data — see [Telemetry](telemetry.md) |

Speech candidates are checked by `first_working()` in
[speech_setup.py](../ansible/roles/ovos_config/files/speech_setup.py).
Its `with_public_fallback()` preserves the locale's public server settings;
[speech.yml](../ansible/roles/ovos_config/tasks/speech.yml) applies the working
models and reports which parts remain public. Regression coverage lives in
[`SpeechSetupTest`](../scripts/test_speech_setup.py).

## Environment variables

Launchers may set `OVOS_INSTALLER_REPORT_FD=3` and open writable descriptor 3
before running `setup.sh`. `on_error()` writes only a validated
`https://paste.uoi.io/<id>` URL and newline after a successful log upload. The ID
contains 1–128 ASCII letters, digits, `_` or `-`; a trailing slash is allowed.
No log contents travel through this descriptor.

The wizard also sets `OVOS_INSTALLER_AUTO_REPORT=1` to upload failure reports
without another Terminal question. This requires both exact flag values and a
usable descriptor. The automatic path uploads only the fresh current run's log,
including its captured Ansible output, only if the complete source fits within
1.5 MB (or a smaller configured limit). Oversized logs stay local: selecting a
tail before filtering could discard a private key's opening marker. It filters
known secret values, including satellite credentials, and common credential fields
before one HTTPS request with certificate
verification; redirects and curl configuration files are disabled. Filtering is
not a promise of anonymity: diagnostic paths and device details may remain.
If preparation, filtering or upload fails, no raw-log fallback is attempted.
The private upload file is removed on return and on INT, TERM or HUP, using
upload-local traps that preserve the installer's existing cleanup.

Standalone installations retain `ask_optin()`: refusal, EOF or no Terminal skips
the upload. A report failure never replaces the installer's failure exit code.
See [`upload_wizard_logs()` and `report_upload_url()`](../utils/common.sh),
[`sanitize()`](../scripts/sanitize_error_log.py), the
[handoff tests](../tests/bats/error_report.bats),
[interruption tests](../tests/bats/error_report_cleanup.bats) and
[sanitizer tests](../scripts/test_sanitize_error_log.py).

For the settings that are not worth a screen of their own. With the `curl`
one-liner they have to go through `sudo env ...` so they reach the installer:

```shell
sudo env DEBUG=true sh -c "$(curl -fsSL https://raw.githubusercontent.com/OpenVoiceOS/ovos-installer/main/installer.sh)"
```

| Variable | What it does |
| --- | --- |
| `DEBUG` | Verbose logging: `bash -x` plus more Ansible output |
| `OVOS_VENV_PYTHON` | Python version for the OVOS virtualenv, default `3.11`. The installer provisions it with `uv` if it is missing |
| `REUSE_CACHED_ARTIFACTS` | Reuse cached downloads between runs, which speeds up repeated installs |
| `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY` | Forwarded into the generated systemd or launchd services |

## Uninstalling non-interactively

```shell
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/OpenVoiceOS/ovos-installer/main/installer.sh)" installer.sh --uninstall
```

Uninstalling removes installed components, configuration and services. Back up
anything you want to keep first.

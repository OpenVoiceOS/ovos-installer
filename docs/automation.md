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
[scenarios/](https://github.com/OpenVoiceOS/ovos-installer/tree/main/scenarios).

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
| `raspberry_pi_tuning` | Maximum-performance tuning for a Pi, including an overclocking prompt |
| `share_telemetry` | Share anonymous usage statistics — see [Telemetry](telemetry.md) |
| `share_usage_telemetry` | Share detailed usage data — see [Telemetry](telemetry.md) |

## Environment variables

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

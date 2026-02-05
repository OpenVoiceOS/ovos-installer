# 🎉 Open Voice OS and HiveMind Installer 🎉

Welcome to the world of Open Voice OS and HiveMind! Get ready for a straightforward journey into voice tech.

## 🤖 What is Open Voice OS?

Open Voice OS (OVOS) is an open-source voice assistant platform that brings privacy-focused, customizable voice technology to your devices. It allows you to control smart home devices, play music, get weather updates, and much more using natural language commands. HiveMind extends this functionality by enabling distributed voice processing across multiple devices.

Key benefits include:
- **Privacy-first**: Your voice data stays on your device
- **Highly customizable**: Add your own skills and integrations
- **Multi-platform support**: Runs on various Linux distributions and hardware
- **Community-driven**: Free and open-source with active development

## 🚀 Quickstart

Before we begin, make sure you have `curl`, `git`, and `sudo` installed. `curl` is used to download the installer script, `git` is needed for cloning repositories during installation, and `sudo` provides administrative privileges required for system changes. Here's your installation incantation:

```shell
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/OpenVoiceOS/ovos-installer/main/installer.sh)"
```

If you prefer to inspect before running, download the script first, review it, then execute it with `sudo sh installer.sh`.

This command downloads and runs the official installer script, which will guide you through the installation process interactively.

> Heads-up: OVOS targets a supported Python runtime in its virtualenv (default `3.11`). The installer uses `uv` to provision that version if it is not already available. You can override with `OVOS_VENV_PYTHON`, but `3.14` is blocked because `onnxruntime` does not provide wheels for it.

👉 [Start your Open Voice OS journey!](https://community.openconversational.ai/t/howto-begin-your-open-voice-os-journey-with-the-ovos-installer/14900)

### 🐧 Supported Linux distributions

The installer has been tested on the following Linux distributions and versions:

| Distribution        | Version   |
| ------------------- | --------- |
| AlmaLinux           | `>= 8`    |
| Arch                | `rolling` |
| CachyOS             | `rolling` |
| CentOS              | `>= 8`    |
| Debian GNU/Linux    | `>= 10`   |
| EndeavourOS         | `rolling` |
| KDE Neon            | `>=20.04` |
| Fedora              | `>= 37`   |
| Linux Mint          | `>= 21`   |
| openSUSE Leap       | `>= 15`   |
| openSUSE Tumbleweed | `rolling` |
| openSUSE Slowroll   | `rolling` |
| Pop!\_OS            | `>=22.04` |
| Manjaro             | `rolling` |
| Raspbian            | `10`      |
| Raspberry Pi OS     | `>= 11`   |
| Rocky Linux         | `>=8`     |
| Ubuntu              | `>=20.04` |
| WSL2                | `20.04`   |
| Zorin OS            | `>= 16`   |

Note: 'rolling' indicates a rolling release Linux distribution, which means there is no specific version number as it continuously updates to the latest software.
Role metadata in `ansible/roles/*/meta/main.yml` lists the base OS families/versions (e.g., Debian/Ubuntu/EL/Fedora/Arch/Suse) that cover these distributions.

## ✨ Key Features

Open Voice OS offers a comprehensive set of features for modern voice interaction:

- **Voice Commands**: Control smart home devices, play music, set timers, and more with natural language
- **Skill System**: Extensible plugin architecture allowing custom voice skills and integrations
- **Multi-Device Support**: Connect multiple devices for coordinated voice experiences
- **Offline Operation**: Process voice commands locally without internet dependency
- **Wake Word Detection**: Customizable hotwords to activate the assistant
- **Text-to-Speech & Speech-to-Text**: High-quality voice synthesis and recognition
- **Docker Support**: Containerized deployment for easy management
- **Hardware Integration**: Support for various microphones, speakers, and displays
- **API Access**: RESTful APIs for programmatic control and integration

## 🔄 Update

Updating Open Voice OS ensures you have the latest features, bug fixes, and security improvements. The update process will download and install the newest version while preserving your existing configuration. Backing up your configuration file is recommended in case you have custom settings that might be affected.

To update the current Open Voice OS instance, backup your `~/.config/mycroft/mycroft.conf` or `~/ovos/config/mycroft.conf` _(only if required)_ and re-run installer but answer **"No"** to the _"Do you want to uninstall Open Voice OS?"_ question.

## ⚙️ Start & Stop the services

When the `virtualenv` method is chosen (default) during the installation process, several systemd unit files are created to manage the different components as services. These services allow Open Voice OS to run automatically in the background.

### 📋 List the systemd unit files

```shell
systemctl --user list-units "*ovos*"
systemctl list-units "*ovos*"
```

Only one service is running as `root`; `ovos-phal-admin`. The `ovos` service runs the main Open Voice OS components as your user, while `ovos-phal-admin` handles administrative tasks that require root privileges, such as managing system hardware interfaces.

### 🟢 Start Open Voice OS

```shell
systemctl --user start ovos
sudo systemctl start ovos-phal-admin
```

### 🔴 Stop Open Voice OS

```shell
systemctl --user stop ovos
sudo systemctl stop ovos-phal-admin
```

## 🎙️ Audio calibration tool

If wake word detection is weak or inconsistent, run the calibration helper to tune your microphone input. The tool records short samples (silence, speech, wake word), measures signal levels, and recommends capture volume and listener multiplier values.

```shell
scripts/audio-calibrate.sh
```

To apply the recommended capture volume automatically:

```shell
scripts/audio-calibrate.sh --apply
```

Bluetooth headsets work too, but the mic typically needs the HFP/HSP profile. The installer will attempt to switch profiles automatically when a Bluetooth mic is the default input.

## 🤖 Automated install

The installer supports a non-interactive _(automated)_ process of installation by using a scenario file, this file must be created under the `~/.config/ovos-installer/` directory and should be named `scenario.yaml`.

A scenario file allows you to pre-configure installation options for automated, non-interactive deployment. This is useful for scripting installations or deploying on multiple devices.

Here is an example of a scenario to install Open Voice OS within Docker containers on a Raspberry Pi 4B with default skills.

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

### Configuration options explained:
- `uninstall`: Set to `true` to uninstall instead of install
- `method`: Installation method (`containers` for Docker, `virtualenv` for Python virtual environment)
- `channel`: Release channel (`stable`, `testing`, `development`)
- `profile`: Installation profile (`ovos` for standard setup)
- `features`: Enable/disable specific features
  - `skills`: Install default voice skills
  - `extra_skills`: Install additional community skills
- `raspberry_pi_tuning`: Enable maximum-performance tuning for Raspberry Pi hardware (includes an overclocking prompt)
- `share_telemetry`: Allow sharing anonymous usage statistics
- `share_usage_telemetry`: Allow sharing detailed usage data

Few scenarios are available as example in the [scenarios](https://github.com/OpenVoiceOS/ovos-installer/tree/main/scenarios) directory of this repository.

## 🧩 Ansible role map

The installer is now modular. The top-level wrapper role (`ovos_installer`) orchestrates focused roles:

- `ovos_facts`: Shared installer facts (boot dir, NetworkManager, systemd drop-ins)
- `ovos_timezone`: Detect and configure system timezone
- `ovos_telemetry`: Optional telemetry submission
- `ovos_config`: Configuration defaults and `mycroft.conf` generation
- `ovos_sound`: Sound server setup (PipeWire/PulseAudio)
- `ovos_services`: Systemd units + handlers
- `ovos_virtualenv`: Python virtualenv provisioning and package install
- `ovos_containers`: Docker/compose provisioning and deployment
- `ovos_finalize`: Post-install cleanup and drift notice
- `ovos_storage_tuning`: fstab/log2ram/tmpfs tuning
- `ovos_audio_tuning`: PipeWire/WirePlumber tuning
- `ovos_python`: Python runtime tuning (mimalloc, env)
- `ovos_performance_tuning`: governor, I/O, zram, sysctl, NUMA, limits
- `ovos_network_tuning`: wireless power + DNS caching
- `ovos_hardware_mark1` / `ovos_hardware_mark2`: hardware-specific roles (still applied when detected)

## ❌ Uninstall

Uninstalling Open Voice OS will remove all installed components, configurations, and services. This process cannot be undone, so ensure you have backed up any important data or custom configurations before proceeding.

To uninstall Open Voice OS run the installer with the `--uninstall` option _(non-interactive)_ or simply run the installer and answer **"Yes"** to the _"Do you want to uninstall Open Voice OS?"_ question.

```shell
sh -c "curl -s https://raw.githubusercontent.com/OpenVoiceOS/ovos-installer/main/installer.sh -o installer.sh && chmod +x installer.sh && sudo ./installer.sh --uninstall && rm installer.sh"
```

## 🖼️ Screenshots

![Screenshot 1](docs/images/screenshot_1.png)

![Screenshot 2](docs/images/screenshot_3.png)

![Screenshot 3](docs/images/screenshot_4.png)

![Screenshot 4](docs/images/screenshot_5.png)

![Screenshot 5](docs/images/screenshot_6.png)

![Screenshot 6](docs/images/screenshot_7.png)

![Screenshot 7](docs/images/screenshot_8.png)

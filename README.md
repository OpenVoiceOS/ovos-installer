# Open Voice OS Installer

Installs [Open Voice OS](https://github.com/OpenVoiceOS/ovos-core), a private,
open-source voice assistant, on a Linux machine, a Raspberry Pi, or a Mac. It
asks a handful of questions and sets up everything else itself.

## Install

```shell
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/OpenVoiceOS/ovos-installer/main/installer.sh)"
```

That is the whole thing. The installer asks a few questions, then does the work.

Answer with the arrow keys and **Enter**. **Back** returns to the previous
screen at any point, and nothing is installed until you have answered every
screen — so you can change your mind, or leave, without touching the system.

You need `curl`, `git`, `sudo`, and Bash 4 or later. macOS needs
[a little setup first](docs/macos.md). To read the script before running it,
download it, look it over, then run `sudo sh installer.sh`.

## Talk to it

The installer tells you when it is done. Then:

> **"Hey Mycroft, what time is it?"**

Others to try: *what is the temperature?*, *who made you?*, *who is Ada
Lovelace?*

If nothing happens, start with [Troubleshooting](docs/troubleshooting.md).

## Everyday tasks

| I want to… | Do this |
| --- | --- |
| Update | Re-run the installer and answer **No** to "uninstall?" |
| Start, stop or check the services | See [Managing OVOS](docs/services.md) |
| Change settings | Edit `~/.config/mycroft/mycroft.conf` |
| Fix a microphone that mishears | [Calibrate it](docs/troubleshooting.md#the-assistant-does-not-answer) |
| Install without answering questions | See [Automation](docs/automation.md) |
| Uninstall | Re-run the installer and answer **Yes** to "uninstall?" |

Back up `~/.config/mycroft/mycroft.conf` (or `~/ovos/config/mycroft.conf` for
container installs) before updating or uninstalling if you want to keep your
settings.

## Will it run on my machine?

Most likely yes. The installer is tested on Debian, Ubuntu and their
derivatives (including Raspberry Pi OS and Linux Mint), Fedora and the
Enterprise Linux family, Arch and its derivatives, openSUSE, WSL2, and macOS on
both Intel and Apple Silicon.

[The full list of tested versions](docs/supported-systems.md) has the details,
including which combinations macOS supports.

## Documentation

- [Managing OVOS](docs/services.md) — starting, stopping and checking services
- [Automation](docs/automation.md) — unattended installs and every setting
- [macOS](docs/macos.md) — extra setup Macs need
- [Supported systems](docs/supported-systems.md) — tested distributions
- [Troubleshooting](docs/troubleshooting.md) — when something goes wrong
- [Telemetry](docs/telemetry.md) — what the optional data sharing sends
- [How it works](docs/architecture.md) — for people changing the installer

## Screenshots

<details>
<summary>The screens the installer walks through</summary>

Rendered from the installer itself by `scripts/render_screenshots.py`, so they
stay in step with it.

![Welcome](docs/images/screenshot_1.png)

![Detected hardware](docs/images/screenshot_2.png)

![Installation method](docs/images/screenshot_3.png)

![Release channel](docs/images/screenshot_4.png)

![Profile](docs/images/screenshot_5.png)

![Features](docs/images/screenshot_6.png)

![Summary](docs/images/screenshot_7.png)

![Finish](docs/images/screenshot_8.png)

</details>

## Related projects

- [ovos-core](https://github.com/OpenVoiceOS/ovos-core) — the assistant this installs
- [HiveMind-core](https://github.com/JarbasHiveMind/HiveMind-core) — distributed voice across several devices, which this can also set up
- [raspOVOS](https://github.com/OpenVoiceOS/raspOVOS) — a prebuilt Raspberry Pi image, if you would rather flash a card than run an installer

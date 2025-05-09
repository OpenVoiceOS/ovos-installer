# 🎉 Open Voice OS and HiveMind Installer 🎉

Welcome to the world of Open Voice OS and HiveMind! Get ready for a straightforward journey into voice tech.

## 🚀 Quickstart

Before we begin, make sure you have `curl`, `git`, and `sudo` installed. Here’s your installation incantation:

```shell
sudo sh -c "$(curl -fsSL https://raw.githubusercontent.com/OpenVoiceOS/ovos-installer/main/installer.sh)"
```

👉 [Start your Open Voice OS journey!](https://community.openconversational.ai/t/howto-begin-your-open-voice-os-journey-with-the-ovos-installer/14900)

### 🐧 Supported Linux distributions

| Distribution        | Version   |
| ------------------- | --------- |
| AlmaLinux           | `>= 8`    |
| Arch                | `rolling` |
| CentOS              | `>= 8`    |
| Debian GNU/Linux    | `>= 10`   |
| EndeavourOS         | `rolling` |
| KDE Neon            | `>=20.04` |
| Fedora              | `>= 37`   |
| Linux Mint          | `>= 21`   |
| openSUSE Leap       | `>= 15`   |
| openSUSE Tumbleweed | `rolling` |
| openSUSE Slowroll   | `rolling` |
| Pop!_OS             | `>=22.04` |
| Manjaro             | `rolling` |
| Raspbian            | `10`      |
| Raspberry Pi OS     | `>= 11`   |
| Rocky Linux         | `>=8`     |
| Ubuntu              | `>=20.04` |
| WSL2                | `20.04`   |
| Zorin OS            | `>= 16`   |

`rolling` as `rolling` Linux distribution which means that there is no specific version.

## 🔄 Update

To update the current Open Voice OS instance, backup your `~/.config/mycroft/mycroft.conf` or `~/ovos/config/mycroft.conf` _(only if required)_ and re-run installer but answer **"No"** to the _"Do you want to uninstall Open Voice OS?"_ question.

## ⚙️ Start & Stop the services

When the `virtualenv` method as being choose _(default)_ during the installation process, few systemd unit files have being created in order to manages the different components as services.

### 📋 List the systemd unit files

```shell
systemctl --user list-units "*ovos*"
systemctl list-units "*ovos*"
```

Only one service is running as `root`; `ovos-phal-admin`.

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

## 🤖 Automated install

The installer supports a non-interactive _(automated)_ process of installation by using a scenario file, this file must be created under the `~/.config/ovos-installer/` directory and should be named `scenario.yaml`.

Here is an example of a scenario to install Open Voice OS within Docker containers on a Raspberry Pi 4B with default skills and GUI support.

```shell
mkdir -p ~/.config/ovos-installer
cat <<EOF > ~/.config/ovos-installer/scenario.yaml
---
uninstall: false
method: containers
channel: development
profile: ovos
features:
  skills: true
  extra_skills: false
  gui: true
rapsberry_pi_tuning: true
share_telemetry: true
share_usage_telemetry: true
EOF
```

Few scenarios are available as example in the [scenarios](https://github.com/OpenVoiceOS/ovos-installer/tree/main/scenarios) directory of this repository.

## ❌ Uninstall

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

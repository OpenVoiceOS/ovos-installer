# Troubleshooting

[Back to the README](../README.md).

## The assistant does not answer

Check the services are running — [Managing OVOS](services.md) has the commands
for your install. If they are running and it still does not hear you, the
microphone is the usual culprit. The calibration helper is a standalone script,
and the installer removes its own copy once it finishes, so fetch it:

```shell
curl -fsSLO https://raw.githubusercontent.com/OpenVoiceOS/ovos-installer/main/scripts/audio-calibrate.sh
bash audio-calibrate.sh
```

It records a few short samples — silence, speech, the wake word — measures the
levels, and recommends a capture volume and listener multiplier. Add `--apply`
to have it set the recommended volume for you.

Bluetooth headsets work, but the microphone needs the HFP/HSP profile. The
installer switches profiles automatically when a Bluetooth microphone is the
default input.

On macOS, an assistant that runs but never hears anything is usually the
microphone permission — see [macOS](macos.md).

## Getting around the installer screens

Every question screen has **Next** and **Back**. Move between them with the
arrow keys or **Tab**, and choose with **Enter**.

**Back** keeps working all the way to the first screen, so an answer you gave
several screens ago is still yours to change. Past the first screen you reach
the language selection, whose **Exit** button leaves the installer. Nothing is
installed until every screen has been answered, so leaving there changes
nothing on the machine.

**Ctrl-C does nothing** while a screen is open, and neither does ESC on many
systems. The installer draws its screens with `whiptail`, which puts the
terminal in raw mode, so the keys never reach it. Use the buttons.

## A screen looks cramped or cut off

The screens fit themselves to the terminal, down to 80x24. In a window too
small for a screen's text, the blank lines between paragraphs are dropped so
the text still fits. If even that is not enough, the text scrolls — and then
the keyboard focus starts in the text rather than on a button, so press **Tab**
to reach **Next** and **Back**.

Making the window taller is the easy fix. Around 30 rows is enough for every
screen to fit without any of this.

## The install failed

The installer writes `/var/log/ovos-installer.log` and the Ansible output to
`/var/log/ovos-ansible.log`. On failure it offers to upload the log and gives
you a URL to share.

Re-running with `DEBUG=true` produces considerably more detail:

```shell
sudo env DEBUG=true sh -c "$(curl -fsSL https://raw.githubusercontent.com/OpenVoiceOS/ovos-installer/main/installer.sh)"
```

If a download failed partway through, `REUSE_CACHED_ARTIFACTS=true` makes a
retry pick up cached artifacts instead of fetching everything again. Conversely,
setting it to `false` forces a clean-room run when you suspect a bad cache.

## Reporting a problem

Open an issue at
[OpenVoiceOS/ovos-installer](https://github.com/OpenVoiceOS/ovos-installer/issues)
with your distribution and version, whether you chose `virtualenv` or
`containers`, and the log URL the installer gave you.

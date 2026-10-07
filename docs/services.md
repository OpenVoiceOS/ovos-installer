# Managing OVOS

How to start, stop and check Open Voice OS after it is installed.
[Back to the README](../README.md).

## Linux

Installs using the `virtualenv` method (the default) get systemd units.

Most installs put them in **user scope**. Installs that enabled Raspberry Pi
tuning put them in **system scope** instead, because the tuning needs it. The
installer tells you which one you got on its last screen; if you no longer have
that, try the user-scope command first and use the system-scope one if it finds
nothing.

### User scope

```shell
systemctl --user list-units 'ovos*'
systemctl --user status ovos.service
systemctl --user start ovos.service
systemctl --user stop ovos.service
systemctl --user restart ovos.service
```

### System scope

```shell
sudo systemctl list-units 'ovos*'
sudo systemctl status ovos.service
sudo systemctl start ovos.service
sudo systemctl stop ovos.service
sudo systemctl restart ovos.service
```

`ovos.service` is the whole assistant. Individual pieces — `ovos-listener`,
`ovos-audio`, `ovos-core`, `ovos-gui` — can be controlled the same way when you
need to poke at one of them.

### The screen restarts itself now and then (Mark II, DevKit)

`ovos-shell`, the program that draws the screen, keeps memory it never gives
back. Weather pages are the worst: each one can cost it tens of megabytes. Its
code is no longer maintained, so this won't be fixed there
([#646](https://github.com/OpenVoiceOS/ovos-installer/issues/646)).

To keep it from filling the memory and slowing the voice down,
`ovos-gui-watchdog.service` restarts the screen once `ovos-shell` holds more
than 30% of the RAM (about 550 MB on a Mark II). The screen goes blank for a few
seconds and comes back on the homescreen. Each restart is logged:

```shell
journalctl --user -u ovos-gui-watchdog.service   # system scope: sudo journalctl -u ...
```

To change the limit, run `systemctl --user edit ovos-gui-watchdog.service`
(`sudo systemctl edit ...` in system scope) and replace the command. The empty
`ExecStart=` line clears the old one first:

```ini
[Service]
ExecStart=
ExecStart=/home/<you>/.venvs/ovos/bin/ovos-gui-watchdog 700 ovos-gui.service --user
```

The first argument is megabytes, or a share of the RAM written with a doubled
percent sign (`40%%`), because systemd reads `%` as the start of a placeholder.
In system scope, the last argument is `--system`.

## macOS

macOS uses `launchd`. The installer deploys an `ovos` wrapper command and
sources it from `~/.zshrc`, so open a new terminal after installing.

```shell
ovos list
ovos status ovos
ovos start ovos-audio
ovos stop ovos
ovos restart ovos-listener
```

`ovos` on its own is a meta target covering every installed OVOS service.

## Containers

Installs using the `containers` method run under Docker instead of systemd.
Manage them with the usual Docker commands by container name - `docker ps`
lists them. `~/ovos` holds the configuration and data the containers mount
(`config/`, `share/`, `tmp/`), not the compose files: those are cloned to
`/tmp/ovos-docker/compose`, or `/tmp/hivemind-docker/compose` for a satellite,
and a `docker compose` command needs `--project-directory` pointed there.

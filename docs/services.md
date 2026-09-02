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
Manage them with the usual Docker commands from `~/ovos`.

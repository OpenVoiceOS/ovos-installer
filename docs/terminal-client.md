# Talking to OVOS from a terminal

You do not need a microphone to use or test Open Voice OS.
[ovos-tui-client](https://github.com/andlo/ovos-tui-client) gives you a
terminal where you type what you would have said, read the reply, and watch
what the assistant is doing while it does it — useful when the microphone is
not set up yet, when you are on a machine without one, or when you want to see
*why* something answered the way it did.

[Back to the README](../README.md).

![ovos-tui-client](images/ovos-tui-client.png)

Four panes: the service logs, the conversation, a plain-English feed of what is
happening on the message bus, and an input box that stands in for your voice.
`Ctrl+P` opens a command palette, `F1` lists the keys.

It is a separate project. Virtualenv installs get it in the box; container
installs run it as a container of its own.

## Running it

### Virtualenv installs

Already installed — this is the default method, and the client goes into the
same virtualenv as OVOS, at `~/.venvs/ovos`, which is how it reads your
configuration and finds the logs:

```shell
~/.venvs/ovos/bin/ovos-tui
```

Add `~/.venvs/ovos/bin` to your `PATH` and it is simply `ovos-tui`. This covers
the `ovos`, `listener` and `server` profiles — a server has no audio at all, so
typing is the only way to talk to it on the box itself.

The `satellite` profile does not get it, since a satellite is an audio front
end for an assistant that lives on another machine. Add it by hand if you want
it there:

```shell
~/.venvs/ovos/bin/pip install ovos-tui-client
```

Do not use `~/.venvs/ovos-installer` — that one belongs to the installer
itself and is removed once an install finishes.

### Container installs

Nothing to install: the client publishes its own image, and a container install
already has Docker, so it is one command.

```shell
docker run -it --rm --network host ghcr.io/andlo/ovos-tui-client:latest
```

`-it` matters — this one is an interactive terminal, not a background service
like the other OVOS containers, and it needs a TTY to draw anything at all.
`--network host` is the simplest way to reach the message bus on
`127.0.0.1:8181`; joining the `ovos-docker` compose network and passing
`--host` the messagebus container's name is the tidier option if you intend to
keep it around.

The installer does not add this to your compose stack, because the client is a
tool you reach for rather than a service that should be running.

Two things it cannot see by default, both deliberate:

- **The logs and service panes need the Docker socket.** The client shells out
  to `docker ps` and `docker logs -f`, so without
  `-v /var/run/docker.sock:/var/run/docker.sock` (plus `--user root`, since the
  image's own user cannot use the socket) those panes are simply empty rather
  than erroring. Mounting the socket hands that container control of the host's
  Docker daemon, which is why it is opt-in.
- **The pipeline view needs the configuration.** Mount the same config volume
  `ovos_core` uses and it reads the real files with no flags at all.

If you would rather run it from Python on the host than as a container,
[pipx](https://pipx.pypa.io/) keeps it out of your system Python — and there
`--mycroft-conf` is needed, since the host has no OVOS virtualenv whose
configuration it can find:

```shell
pipx install ovos-tui-client
ovos-tui --mycroft-conf ~/ovos/config/mycroft.conf
```

`--mycroft-conf` matters here. Without it the client looks for the
configuration where a virtualenv install would keep it and finds the wrong file
or none, which makes the command palette's pipeline view inaccurate. It does
not crash, it just tells you the wrong thing.

Two other differences on containers, both upstream limitations rather than
configuration you can fix:

- **Logs still work.** Container installs often log to stdout with no log files
  on the host at all. The client notices that and bridges `docker logs -f` (or
  `podman logs -f`) into the usual per-service view.
- **Service restarts and skill activation are limited.** Restarting a container
  from inside the client is not supported yet, and activating or deactivating
  individual skills does not work reliably on installs that run one container
  per skill.

### macOS

macOS installs are always virtualenv, so the client is already there. It is
pure Python and behaves the same as on Linux.

## Connecting to another machine

By default it connects to `127.0.0.1:8181`, the message bus on the machine it
runs on. To drive a Raspberry Pi from your laptop, point it at the Pi:

```shell
ovos-tui --host 192.168.1.50
```

The message bus is not authenticated, so only do this on a network you trust.

## If the logs pane is empty

The client finds the log directory itself, but a non-standard install can defeat
that. Point it at the right place:

```shell
ovos-tui --log-dir ~/.local/state/mycroft
```

## More

The project's own [README](https://github.com/andlo/ovos-tui-client) covers the
rest, including running it as a web app in a browser instead of a terminal, and
[the announcement post](https://blog.openvoiceos.org/posts/2026-07-24-a-terminal-client-for-testing-ovos)
explains the thinking behind it.

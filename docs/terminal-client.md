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

It is a separate project, not part of this installer, so the installer does not
put it there for you — but it talks to any OVOS this installer sets up.

## Installing it

It is a Python package and works the same on Linux and macOS. Which Python you
put it in depends on how you installed OVOS.

### Virtualenv installs

This is the default method. OVOS lives in `~/.venvs/ovos`, and the client is
designed to sit in the same virtualenv, which lets it read your OVOS
configuration and find the logs on its own:

```shell
~/.venvs/ovos/bin/pip install ovos-tui-client
~/.venvs/ovos/bin/ovos-tui
```

Add `~/.venvs/ovos/bin` to your `PATH` and it is simply `ovos-tui`.

Do not use `~/.venvs/ovos-installer` — that one belongs to the installer
itself and is removed once an install finishes.

### Container installs

OVOS runs in containers, so there is no OVOS virtualenv on the host to join.
The client runs on the host and reaches the containers over the message bus.
Install it wherever you like — [pipx](https://pipx.pypa.io/) keeps it out of
your system Python:

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

macOS installs are always virtualenv, so follow the virtualenv instructions
above. The client is pure Python and behaves the same there.

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

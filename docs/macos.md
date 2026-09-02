# macOS

Open Voice OS runs on both Intel and Apple Silicon Macs.
[Back to the README](../README.md).

## Before you install

- **Homebrew**, installed and on your `PATH`.
- **Bash 4 or later**: `brew install bash`. macOS ships Bash 3, which the
  installer cannot run on. Your login shell can stay zsh.
- **Xcode Command Line Tools**: `xcode-select --install`.
- **Microphone permission** for your terminal app, under
  System Settings → Privacy & Security → Microphone. Without it the assistant
  starts but never hears you.

## What macOS supports

One combination, and the installer will not offer you the others:

- Method: `virtualenv`
- Channel: `alpha`

## After installing

Services run under `launchd` rather than systemd, and the installer adds an
`ovos` command for managing them — see [Managing OVOS](services.md). It is
sourced from `~/.zshrc`, so open a new terminal before using it.

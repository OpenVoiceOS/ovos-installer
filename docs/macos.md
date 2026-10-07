# macOS

Open Voice OS runs on Apple Silicon Macs with macOS 15 or later. Homebrew has
stopped building new packages for Intel Macs, and rarely builds them for
macOS 14, which it no longer supports. It will not install a formula that has
no package for your Mac unless asked to build it from source, which the
installer does not do, so an install there stops at the first such formula.
On an Intel Mac or macOS 14 the installer therefore stops before it changes
anything, and says why. Run it with `OVOS_INSTALLER_ALLOW_UNSUPPORTED_MACOS=true`
to try anyway on a Mac that already has the packages it needs. An existing
install only gets a warning, so it can still be uninstalled.
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

# Supported systems

Versions the installer has been tested against.
[Back to the README](../README.md).

`rolling` means a rolling-release distribution with no fixed version number.

| Distribution | Version |
| --- | --- |
| AlmaLinux | `>= 8` |
| Arch | `rolling` |
| CachyOS | `rolling` |
| CentOS | `>= 8` |
| Debian GNU/Linux | `>= 10` |
| EndeavourOS | `rolling` |
| Fedora | `>= 37` |
| KDE Neon | `>= 20.04` |
| Linux Mint | `>= 21` |
| Manjaro | `rolling` |
| openSUSE Leap | `>= 15` |
| openSUSE Slowroll | `rolling` |
| openSUSE Tumbleweed | `rolling` |
| Pop!\_OS | `>= 22.04` |
| Raspberry Pi OS | `>= 11` |
| Raspbian | `10` |
| Rocky Linux | `>= 8` |
| Ubuntu | `>= 20.04` |
| WSL2 | `20.04` |
| Zorin OS | `>= 16` |

macOS is supported on Intel and Apple Silicon, with [some extra setup](macos.md).

A distribution not on this list may still work if it is close to one that is:
the roles declare which OS families they support in
`ansible/roles/*/meta/main.yml` (Debian/Ubuntu, EL, Fedora, Arch, SUSE).

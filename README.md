[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Arch Linux](https://img.shields.io/badge/OS-Arch_Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://archlinux.org)

[![Jay-bin](https://img.shields.io/badge/JAY_BIN-v7.3.0-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://aur.archlinux.org/packages/jay-bin)

# JAY 
Just Another Yogourt

A lightweight, human-friendly AUR helper wrapper with Flatpak integration, multi-language support, and automated system safety.

## Features

- **Human Syntax** —            Use `install`, `update`, or `remove` instead of complex, hard-to-remember arguments.
- **Multi-backend Support** —   Dynamically hooks into `yay`, `paru`, `pikaur`, or cleanly falls back to a limited `pacman` instance.
- **Hybrid Mode (`-f`)** —      Seamless fallback to Flathub if an application isn't hosted or found natively in the Arch Repositories/AUR.
- **Aggressive Mode (`ra`)** —  Purge target packages along with their entire unused cascading dependency tree (`-Rsn`).
- **Auto-Logging & Rotation** — Records detailed logs in `~/.cache/jay.log` with a built-in automated 500KB rotater mechanism.
- **Package Pinning** — Toggle `IgnorePkg` entries in your `/etc/pacman.conf` safely on-the-fly without manual text editing.

## Installation

### Prerequisites


```bash
sudo pacman -S --needed git base-devel

```

*It is recommended to have an AUR helper installed on your system.*

**Recommended AUR helpers:**

[![Paru](https://img.shields.io/badge/paru-777777?style=flat-square&logo=github&logoColor=white)](https://github.com/morganamilo/paru)
[![Yay](https://img.shields.io/badge/yay-777777?style=flat-square&logo=github&logoColor=white)](https://github.com/jguer/yay)

---

### From source

```bash
git clone https://github.com/xmlzitos154/jay.git
cd jay
chmod +x install.sh
sudo ./install.sh

```

### From the AUR

```bash
# with yay
yay -S jay-bin

# with paru
paru -S jay-bin

```

---

## Usage

```bash
jay [command] [options] [packages]

```

### Primary Commands

| Command | Alias | Description |
| --- | --- | --- |
| `install` | `-i` | Sync and install packages |
| `remove` | `-r` | Cleanly remove packages from the system (Use -ra / remove-agressive to remove dependencies too) |
| `update` | `-u` | Full system update |
| `search` | `-s` | Query packages globally across repositories |
| `query` | `-q` | Search through locally installed system packages |
| `orphan` | `-o` | Find and purge unneeded orphaned dependencies |
| `cache` | `-c` | Flush Pacman, Flatpak and AUR backend cache storage |
| `mirrors` | `-m` | Optimize and sort fastest mirrorlists via Reflector |
| `why`, `dp` |  | Generate reverse dependency maps with suggested removal orders |
| `snap`, `--create-snapshot` |  | Instantly generate a system state checkpoint via Timeshift |
| `pin`, `--ignore` |  | Toggle specific package blocks during upgrade runs |
| `stats` |  | View package disk usage, installation birth-date, and top 10 heaviest structures |
| `--check-updates` | `check` | Search and print pending available updates |
| `--pacdiff` | `pd` | Safely manage emergent `.pacnew` / `.pacsave` configurations |
| `--view` | `vi` | Directly audit the PKGBUILD source file of AUR packages |
| `--list-aur` | `la` | List exclusively all custom packages pulled from the AUR |
| `--ping` |  | Fire an animated terminal health-check against network infrastructure |
| `--fix-keys` | `fk` | Wipe and re-import corrupted GPG keys |
| `--no-log` |  | Don't log the executed command |
| `--create-backup` | `cb` | Backup local package maps complete with SHA256 integrity validation |
| `--restore-backup` | `rb` | Mass-reinstall packages structured within an active JAY backup list |

### Power-User Options

| Option | Description |
| --- | --- |
| `-f`, `--flatpak` | Trigger explicit cross-hybrid package lookups (Native Repos + Flathub) |
| `--flatpak-only` | Enforce full sandboxed Flatpak-only isolation boundaries |
| `--dry-run` | Intercept execution and mirror command layouts without applying filesystem modifications |
| `-nc`, `--noconfirm` | Bypass package compilation interactive prompt menus |
| `--backend` | Override default helper logic manually (yay, paru, pikaur) |
| `--path-to-binary` | Trace real absolute paths of binaries (combine with query) |
| `--lines N` | Truncate and tail explicit log outputs (combine with slog) |
| `--debug` | Print every command that jay is running |

---

## Examples

```bash
# Safely simulate a heavy installation process
jay install blender --dry-run

# Force a standalone system checkpoint right now
jay --create-snapshot

# Update all packages, update flatpaks, and auto-generate an upgrade snapshot
jay update -f

# Remove an infrastructure block alongside hidden configurations aggressively
jay remove docker -A

# Check software dependencies before invoking structural changes
jay why electron

# Toggle package ignore rules programmatically
jay pin linux-lts

# Query an application across multiple isolated ecosystems
jay search postman -f

# Switch engines temporarily for a specific routine
jay --backend paru update

# Review the last 15 actions committed by JAY
jay slog --lines 15

# Wipe and clear out the local cache log file completely
jay clog

```

---

## Log Management

JAY acts transparently by journaling runtime operations directly inside `~/.cache/jay.log`.

```bash
jay slog              # view the total history stream
jay slog --lines 25   # inspect the recent 25 events
jay clog              # clears out the log file completely

```

Log files are monitored dynamically. When total allocations push past 500KB, JAY engages the user to handle clean rotation to `jay.log.1`.

---

## Backup and Restores

Backups generated through JAY map system configurations explicitly and bundle precise SHA256 checksum validations to counter bit-rot or payload manipulation.

```bash
jay --create-backup                          # dumps safe structures inside default directories
jay --restore-backup                         # verifies integrity hashes and applies syncs
jay --restore-backup --path ~/safe_state.txt # handles targets outside default environment caches

```

---

## License

Distributed under the MIT License. Developed with love by xmlzitos154.

Current version: **7.3.0** (Cheesecake)

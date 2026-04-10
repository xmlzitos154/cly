# 🍦 JAY — Just Another Yogourt
> **A lightweight, human-friendly wrapper for `yay` with Flatpak integration.**

[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Jay-bin](https://img.shields.io/badge/OS-Arch_Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://aur.archlinux.org/packages/jay-bin)
[![Arch Linux](https://img.shields.io/badge/OS-Arch_Linux-1793D1?style=flat-square&logo=arch-linux&logoColor=white)](https://archlinux.org/)

JAY is a **powerful yet simple** wrapper designed to make AUR management intuitive. No more memorizing cryptic flags like `-Syyu` — just use plain English and let JAY handle the rest.

---

## 🚀 Key Features

* **✨ Human Syntax:** Use `install`, `update`, or `remove` instead of complex flags.
* **📦 Hybrid Mode (`-f`):** Seamless fallback to **Flathub** if a package isn't found in the AUR.
* **🛡️ Aggressive Mode (`-A`):** Purge packages along with all unneeded dependencies (`-Rsn`).
* **📜 Auto-Logging:** Every action is recorded in `~/.cache/jaylog.txt` for easy tracking.
* **🧹 Orphan Purge:** One-click removal of unused dependencies.

---

## 🛠️ Prerequisites

Ensure you have the essentials installed before running JAY:

```bash
sudo pacman -S --needed git base-devel yay
```
📥 Installation

Ready to simplify your Arch life? Just run these commands:
Bash
```
git clone https://github.com/xmlzitos154/jay.git
cd jay
chmod +x install.sh
sudo ./install.sh
```
if you want to install with AUR:
With yay:
```
yay -S jay-bin
```
Or paru:
```
paru -S jay-bin
```

📖 Usage Guide

The syntax is straightforward: jay [command] [options] [packages]
Primary Commands
Command	Alias	Description
install	-i	Sync and install packages (AUR/Repo)
remove	-rm	Remove packages from the system
update	-u	Full system update (AUR + Flatpaks)
search	-s	Search for packages in repositories
query	-q	Search for locally installed packages
refresh	-r	Force refresh package databases
orphan	-o	Remove all orphaned dependencies
cache	-c	Clear Pacman and AUR cache
Power-User Options

    -f, --flatpak: Enables hybrid search/update for Flatpaks.

    -A: Aggressive Mode (use with remove). Equivalent to -Rsn.

    --noconfirm: Skips AUR confirmation prompts for automation.

    --fix-keys: Fix GPG Keys issues

    --check-updates: Search for updates in AUR

Log Management

Keep track of your system changes:

    jay slog: Displays formatted command history.

    jay clog: Clears the log file.

📄 License

Distributed under the MIT License. Created by xmlzitos154.
Version 3.3.6

Tip: If you like JAY, don't forget to leave a star to support the project!

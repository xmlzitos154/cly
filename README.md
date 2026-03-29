Ah, saquei o que rolou! Quando eu coloquei dentro de um bloco de código text, o GitHub renderizou o conteúdo literalmente (com os símbolos de Markdown aparecendo) em vez de transformar aquilo em títulos, tabelas e links bonitões.

Para o GitHub renderizar o visual "pro" que a gente montou, o conteúdo tem que estar fora de um bloco de código global.

Mas relaxa, vou mandar o código exatamente como você tem que copiar. É só clicar no botão de copiar deste bloco abaixo, abrir seu README.md, apagar tudo que tem lá e colar isso:
Plaintext

# 🍦 JAY — Just Another Yogourt
> **A lightweight, human-friendly wrapper for `yay` with Flatpak integration.**

[![Bash](https://img.shields.io/badge/Language-Bash-4EAA25?style=flat-square&logo=gnu-bash&logoColor=white)](https://www.gnu.org/software/bash/)
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

📥 Installation

Ready to simplify your Arch life? Just run these commands:
Bash

git clone [https://github.com/xmlzitos154/jay-yay.git](https://github.com/xmlzitos154/jay-yay.git)
cd jay-yay
chmod +x install.sh
sudo ./install.sh

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

Log Management

Keep track of your system changes:

    jay slog: Displays formatted command history.

    jay clog: Clears the log file.

📄 License

Distributed under the MIT License. Created by xmlzitos154.

Tip: If you like JAY, don't forget to leave a ⭐ to support the project!

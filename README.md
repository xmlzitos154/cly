# 🍦 JAY (Just Another Yogurt)

JAY is a lightweight Bash wrapper designed to simplify and automate AUR helper tasks. It provides a more human-readable syntax, while keeping a persistent log of your actions.

## 🚀 Features
* **Intuitive Commands:** Forget cryptic flags like `-Syyu`. Use `update`, `refresh`, or `install`.
* **Action Logging:** Every success or failure is logged in `~/.cache/jaylog.txt`.
* **Interactive Installer:** Simple script to install or remove JAY from your system.

## 🛠️ Dependencies
Ensure you have the following installed:
* `base-devel` & `git`
* `yay`

```bash
sudo pacman -S --needed git base-devel

📥 Installation
Bash

git clone https://github.com/xmlzitos154/jay-yay.git
cd jay-yay
chmod +x install.sh
sudo ./install.sh

📖 Usage

JAY follows a simple structure: jay [command] [package]
Helper Flags

Primary Commands
Command	Alias for Description
install	-S	    Installs a package
remove	-Rsn	Removes package and dependencies
update	-Syu	Updates the system
refresh	-Syy	Forces refresh of databases
refdate	-Syyu	Refresh + System update
search	-Ss	    Search in repositories/AUR
query	-Qs	    Search installed packages
cache   -Scc    Clear all pacman and AUR cache
Log Management

    slog: Displays your JAY history.

    clog: Clears the log file.

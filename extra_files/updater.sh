#!/usr/bin/env bash

## Script for update cly for non-aur users

REAL_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_HOME=${REAL_HOME:-/home/$REAL_USER}
REAL_USER="${SUDO_USER:-$USER}"
SOURCE="$SCRIPT_DIR/main.sh"

if [[ ! -f "$SOURCE" ]]; then
    echo -e "${R}Error: File 'main' not found.${NC}"
    exit 1
fi

command -v pacman &>/dev/null || { echo -e "This program is made to run on Arch linux. why are you trying to install it?"; exit 1; }

BIN_NAME="cly"
MODULE_PATH="/usr/share/$BIN_NAME"
INSTALL_PATH="/usr/bin/$BIN_NAME"

[[ $EUID -ne 0 ]] && { echo -e "${Y}>>${NC} Soliciting root..."; exec sudo "$0" "$@"; }

### FUNCTIONS ###

title() { clear; echo -e "${C}${B}CLY SETUP ${NC}"; echo -e "${C}──────────────────────────────${NC}"; }
step() { echo -e "${C}  [..]${NC} $1"; sleep 0.3; }
success() { echo -e "${G}  [OK]${NC} $1"; }

title
step "Installing binary to $INSTALL_PATH..."
install -Dm755 "$SOURCE" "$INSTALL_PATH"
success "Binary installed."
step "Installing languages modules..."
if [[ ! -f "$SCRIPT_DIR/languages/lang_mod_en.sh" || ! -f "$SCRIPT_DIR/languages/lang_mod_pt.sh" ]]; then
    echo "Can't find one or more language modules."
    exit 1
fi
install -Dm644 "$SCRIPT_DIR/languages/lang_mod_en.sh" "$MODULE_PATH/languages/lang_mod_en.sh"
install -Dm644 "$SCRIPT_DIR/languages/lang_mod_pt.sh" "$MODULE_PATH/languages/lang_mod_pt.sh"
success "Done."
step "Installing main modules..."
if [[ ! -f "$SCRIPT_DIR/modules/mod_01.sh" ||  ! -f "$SCRIPT_DIR/modules/mod_02.sh" || ! -f "$SCRIPT_DIR/modules/mod_03.sh" || ! -f "$SCRIPT_DIR/modules/mod_04.sh" || ! -f "$SCRIPT_DIR/modules/mod_05.sh" ]]; then
    echo "Can't find one or more modules."
    exit 1
fi
if [[ ! -f "$SCRIPT_DIR/extra_files/infected_packages.txt" ]]; then
    echo "Can't find 'infected_packages.txt' file. (text file for AUR attack verification.)"
    exit 1
fi
install -Dm644 "$SCRIPT_DIR/modules/mod_01.sh" "$MODULE_PATH/mod_01.sh"
install -Dm644 "$SCRIPT_DIR/modules/mod_02.sh" "$MODULE_PATH/mod_02.sh"
install -Dm644 "$SCRIPT_DIR/modules/mod_03.sh" "$MODULE_PATH/mod_03.sh"
install -Dm644 "$SCRIPT_DIR/modules/mod_04.sh" "$MODULE_PATH/mod_04.sh"
install -Dm644 "$SCRIPT_DIR/modules/mod_05.sh" "$MODULE_PATH/mod_05.sh"
install -Dm644 "$SCRIPT_DIR/extra_files/infected_packages.txt" "$MODULE_PATH/infected_packages.txt"
echo -e "\n${G}${B}Done!${NC} CLY updated successfully."
read -n1 -s -p "Press any key to exit..."
cd ..
rm -fr "cly"
exit 0
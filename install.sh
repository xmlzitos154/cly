#!/usr/bin/env bash

## CLY Installation script

G='\e[32m'; C='\e[36m'; Y='\e[33m'; R='\e[31m'; B='\e[1m'; NC='\e[0m'

### Variables ###

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
REAL_HOME=${REAL_HOME:-/home/$REAL_USER}
SOURCE="$SCRIPT_DIR/modules/mod_main.sh"
CONFIG_FOLDER="$REAL_HOME/.config/cly"

binary_version=$(grep -oP '(?<=ver=")[^"]+' "$SCRIPT_DIR/modules/mod_main.sh")

if [[ ! -f "$SOURCE" ]]; then
    echo -e "${R}Error: Module 'mod_main.sh' not found.${NC}"
    exit 1
fi

command -v pacman &>/dev/null || { echo -e "This program is made to run on Arch linux. why are you trying to install it?"; exit 1; }

BIN_NAME="cly"
MODULE_PATH="/usr/share/$BIN_NAME"
INSTALL_PATH="/usr/bin/$BIN_NAME"

[[ $EUID -ne 0 ]] && { echo -e "${Y}::${NC} Soliciting root..."; exec sudo "$0" "$@"; }

[[ -d "$MODULE_PATH" ]] && rm -fr "$MODULE_PATH" ## <- adding this for remove modules from the old directory path

### Functions ###

title() { clear; echo -e "${C}${B} :: CLY setup ${NC}"; echo -e "${C}──────────────────────────────${NC}"; }
step() { echo -e "${C}  [..]${NC} $1"; sleep 0.3; }
success() { echo -e "${G}  [OK]${NC} $1"; }

installer() {
    title
    echo -e "  ${C}CLY Version: $binary_version"
    echo ""
    step "Installing binary to $INSTALL_PATH..."
    install -Dm755 "$SOURCE" "$INSTALL_PATH"
    success "Binary installed."
    
    step "Installing languages modules..."
    if [[ ! -f "$SCRIPT_DIR/languages/lang_mod_en.sh" || ! -f "$SCRIPT_DIR/languages/lang_mod_pt.sh" || ! -f "$SCRIPT_DIR/languages/lang_mod_es.sh" ]]; then
        echo "Can't find one or more language modules."
        exit 1
    fi
    install -Dm644 "$SCRIPT_DIR/languages/lang_mod_en.sh" "$MODULE_PATH/languages/lang_mod_en.sh"
    install -Dm644 "$SCRIPT_DIR/languages/lang_mod_pt.sh" "$MODULE_PATH/languages/lang_mod_pt.sh"
    install -Dm644 "$SCRIPT_DIR/languages/lang_mod_es.sh" "$MODULE_PATH/languages/lang_mod_es.sh"
    success "Language modules installed."
    
    step "creating config file..."
    mkdir -p "$CONFIG_FOLDER"
    if [[ ! -f "$SCRIPT_DIR/components/base_config" ]]; then
        echo "Can't find base config file."
        rm -fr "$CONFIG_FOLDER"
        exit 1
    fi
    [[ ! -f "$CONFIG_FOLDER/config" ]] && install -Dm644 -o "$REAL_USER" -g "$REAL_USER" "$SCRIPT_DIR/components/base_config" "$CONFIG_FOLDER/config"
    install -Dm644 "$SCRIPT_DIR/components/base_config" "$MODULE_PATH/components/example_config"
    success "Config file created."
    
    step "Installing function modules..."
    if [[ ! -f "$SCRIPT_DIR/modules/mod_01.sh" ||  ! -f "$SCRIPT_DIR/modules/mod_02.sh" || ! -f "$SCRIPT_DIR/modules/mod_03.sh" || ! -f "$SCRIPT_DIR/modules/mod_04.sh" || ! -f "$SCRIPT_DIR/modules/mod_05.sh" ]]; then
        echo "Can't find one or more function modules."
        exit 1
    fi
    install -Dm644 "$SCRIPT_DIR/modules/mod_01.sh" "$MODULE_PATH/execution-modules/mod_01.sh"
    install -Dm644 "$SCRIPT_DIR/modules/mod_02.sh" "$MODULE_PATH/execution-modules/mod_02.sh"
    install -Dm644 "$SCRIPT_DIR/modules/mod_03.sh" "$MODULE_PATH/execution-modules/mod_03.sh"
    install -Dm644 "$SCRIPT_DIR/modules/mod_04.sh" "$MODULE_PATH/execution-modules/mod_04.sh"
    install -Dm644 "$SCRIPT_DIR/modules/mod_05.sh" "$MODULE_PATH/execution-modules/mod_05.sh"
    success "Function modules installed."
    
    step "Installing AUR infected programs list..."
    if [[ ! -f "$SCRIPT_DIR/components/infected_packages.txt" ]]; then
        echo "Can't find 'infected_packages.txt' file. (text file for AUR attack verification.)"
        exit 1
    fi
    install -Dm644 "$SCRIPT_DIR/components/infected_packages.txt" "$MODULE_PATH/components/infected_packages.txt"
    success "AUR infected programs list installed."
    
    step "Adjusting permissions for $REAL_USER"
    chmod +x "$INSTALL_PATH"
    success "Done."
    
    echo -e "\n${G}${B}Done!${NC} cly installed successfully."
    read -n1 -s -p "Press any key to exit..."
    exit 0
}

remover() {
    title
    echo -e "  ${C}CLY Version: $binary_version"
    echo ""
    echo -e "${R}${B}Uninstalling cly...${NC}\n"
    step "Removing binary..."
    rm -f "$INSTALL_PATH"
    success "Binary removed."
    
    step "Removing logs..."
    find "$REAL_HOME/.cache" -maxdepth 1 -iname "*cly*" -delete
    success "logs removed."
    
    step "Removing modules..."
    rm -fr "$MODULE_PATH"
    success "modules removed."
    
    [[ -d "$REAL_HOME/.local/share/cly" ]] && rm -fr "$REAL_HOME/.local/share/cly" && success "Config/backup removed."
    
    [[ -d "/usr/share/doc/cly" ]] && step "Removing README.md..." && rm -fr "/usr/share/doc/cly" && success "README.md Removed (why do you have this?)" # <-- if someones install cly with aur, and uninstall with this script for some reason.
    
    echo -e "\n${Y}Uninstallation complete.${NC}"
    read -n1 -s -p "Press any key to exit..."
    exit 0
}

### Execution ###

while true; do
    title
    echo -e "  ${C}1.${NC} Install / Update"
    echo -e "  ${C}2.${NC} Remove"
    echo -e "  ${C}3.${NC} Exit"
    echo ""
    echo -n " > "
    read -r DO
    
    case "$DO" in
        1) installer ;;
        2) remover   ;;
        3) exit 0    ;;
        *) echo -e "${R}Invalid option.${NC}"; sleep 0.5 ;;
    esac
done
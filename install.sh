#!/usr/bin/env bash
G='\e[32m'; C='\e[36m'; Y='\e[33m'; R='\e[31m'; B='\e[1m'; NC='\e[0m'

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
REAL_HOME=${REAL_HOME:-/home/$REAL_USER}
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/main"

if [[ ! -f "$SOURCE" ]]; then
    echo -e "${R}Error: File 'main' not found.${NC}"
    exit 1
fi

BIN_NAME="jay"
INSTALL_PATH="/usr/bin/$BIN_NAME"
MODULE_PATH="/usr/share/jay"
[[ $EUID -ne 0 ]] && { echo -e "${Y}>>${NC} Soliciting root..."; exec sudo "$0" "$@"; }

title() { clear; echo -e "${C}${B}JAY SETUP - VER 1.1 ${NC}"; echo -e "${C}──────────────────────────────${NC}"; }
step() { echo -e "${C}  [..]${NC} $1"; sleep 0.3; }
success() { echo -e "${G}  [OK]${NC} $1"; }

installer() {
    title
    step "Installing binary to $INSTALL_PATH..."
    install -Dm755 "$SOURCE" "$INSTALL_PATH"
    success "Binary installed."
    step "Installing languages modules..."
    install -Dm644 "$SCRIPT_DIR/languages/en.sh" "$MODULE_PATH/en.sh"
    install -Dm644 "$SCRIPT_DIR/languages/pt.sh" "$MODULE_PATH/pt.sh"
    success "Done."
    step "Installing main modules..."
    install -Dm644 "$SCRIPT_DIR/modules/base.sh" "$MODULE_PATH/base.sh"
    install -Dm644 "$SCRIPT_DIR/modules/logging.sh" "$MODULE_PATH/logging.sh"
    install -Dm644 "$SCRIPT_DIR/modules/cache.sh" "$MODULE_PATH/cache.sh"
    install -Dm644 "$SCRIPT_DIR/modules/flatpak.sh" "$MODULE_PATH/flatpak.sh"
    install -Dm644 "$SCRIPT_DIR/modules/etc.sh" "$MODULE_PATH/etc.sh"
    step "Adjusting permissions for $REAL_USER"
    chmod +x "$INSTALL_PATH"
    success "Done."
    echo -e "\n${G}${B}Done!${NC} Jay installed successfully."
    read -n1 -s -p "Press any key to exit..."
    exit 0
}

remover() {
    title
    echo -e "${R}${B}Removing JAY...${NC}\n"
    step "Removing files..."
    rm -f "$INSTALL_PATH"
    success "Binary removed."
    rm -f "$REAL_HOME/.cache/jay.log"
    success "logs removed."
    rm -fr "$MODULE_PATH"
    success "modules removed."
    rm -fr "$REAL_HOME/.local/share/jay"
    success "Config/backup removed."
    echo -e "\n${Y}Uninstallation complete.${NC}"
    read -n1 -s -p "Press any key to exit..."
    exit 0
}

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
        2) remover ;;
        3) exit 0 ;;
        *) echo -e "${R}Invalid option.${NC}"; sleep 0.5 ;;
    esac
done

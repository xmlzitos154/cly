#!/usr/bin/env bash
G='\e[32m'; C='\e[36m'; Y='\e[33m'; R='\e[31m'; B='\e[1m'; NC='\e[0m'

REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" 2>/dev/null | cut -d: -f6)
REAL_HOME=${REAL_HOME:-/home/$REAL_USER}
CONFIG_DIRECTORY="$REAL_HOME/.config/jay"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/main"
if [[ -f "$SOURCE" ]]; then
    VER=$(sed -n 's/^VER="\(.*\)"/\1/p' "$SOURCE" | head -1)
    [[ -z "$VER" ]] && VER="unk"
else
    echo -e "${R}Error: File 'main' not found.${NC}"
    exit 1
fi

BIN_NAME="jay"
INSTALL_PATH="/usr/bin/$BIN_NAME"
[[ $EUID -ne 0 ]] && { echo -e "${Y}>>${NC} Soliciting root..."; exec sudo "$0" "$@"; }

title() { clear; echo -e "${C}${B}JAY SETUP${NC} — v$VER"; echo -e "${C}──────────────────────────────${NC}"; }
step() { echo -e "${C}  [..]${NC} $1"; sleep 0.3; }
success() { echo -e "${G}  [OK]${NC} $1"; }

new_installer() {
    titles
    step "Installing binary to $INSTALL_PATH..."
    install -Dm755 "$SOURCE" "$INSTALL_PATH"
    success "Binary installed."

    step "Configuring completions..."
    if [ -d "/usr/share/fish/vendor_completions.d" ]; then
        cat <<EOF > "/usr/share/fish/vendor_completions.d/jay.fish"
complete -c jay -f
complete -c jay -n "__fish_use_subcommand" -a "install remove refresh update search query cache slog clog orphan help"
complete -c jay -s i -l install -d "Instalar pacotes"
complete -c jay -s rm -l remove -d "Remover pacotes"
complete -c jay -s u -l update -d "Atualizar sistema"
complete -c jay -s s -l search -d "Pesquisar pacotes"
complete -c jay -s f -l flatpak -d "Modo híbrido/duplo (AUR + Flatpak)"
complete -c jay -s o -l orphan -d "Remover órfãos"
complete -c jay -s sl -l slog -d "Ver histórico"
complete -c jay -s cl -l clog -d "Limpar histórico"
EOF
        success "Fish completions configured."
    fi
    mkdir -p "$CONFIG_DIRECTORY"
    chown -R "$REAL_USER:$REAL_USER" "$CONFIG_DIRECTORY"
    success "Adjusted permissions for $REAL_USER."

    echo -e "\n${G}${B}Done!${NC} Jay installed successfully."
    read -n1 -s -p "Press any key to back..."
}

run_remove() {
    title
    echo -e "${R}${B}Removing JAY...${NC}\n"
    step "Removing files..."
    rm -f "$INSTALL_PATH"
    rm -f "/usr/share/fish/vendor_completions.d/jay.fish"
    rm -rf "$CONFIG_DIRECTORY"
    success "System clear."
    echo -e "\n${Y}Uninstallation complete.${NC}"
    read -n1 -s -p "Press any key to back..."
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
        1) new_installer ;;
        2) run_remove ;;
        3) echo -e "${C}Até logo!${NC}"; exit 0 ;;
        *) echo -e "${R}Opção inválida.${NC}"; sleep 0.5 ;;
    esac
done
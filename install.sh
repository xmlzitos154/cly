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
    title
    step "Copying necessary files..."
    install -Dm755 "$SOURCE" "$INSTALL_PATH"
    success "Done."
    step "Creating config folders..."
    mkdir -p "$CONFIG_DIRECTORY" || exit 1
    cd "$CONFIG_DIRECTORY" || exit 1
    step "Loading basic modules..."
    [[ -d "modules" ]] && rm -rf "modules"
    mkdir "modules"
    [[ ! -f "$SCRIPT_DIR/modules/base" ]] && echo -e "${R}error: base module not found.${NC}" && exit 1
    [[ ! -f "$SCRIPT_DIR/modules/log" ]] && echo -e "${R}error: log module not found.${NC}" && exit 1
    cp -r "$SCRIPT_DIR/modules/base" "$CONFIG_DIRECTORY/modules/"
    cp -r "$SCRIPT_DIR/modules/log" "$CONFIG_DIRECTORY/modules/"
    success "Done."
    echo "Select modules to install"
    echo ""
    echo "1. cache (clear all cache)"
    echo "2. search (search and query of yay)"
    echo "3. extra (Another useful options)"
    echo "4. todos"
    echo "5. nenhum"
    echo ""
    echo -n " > "
    read -r MODS
    case "$MODS" in
        "1") cp -r "$SCRIPT_DIR/modules/cache" "$CONFIG_DIRECTORY/modules" ;;
        "2") cp -r "$SCRIPT_DIR/modules/search" "$CONFIG_DIRECTORY/modules" ;;
        "3") cp -r "$SCRIPT_DIR/modules/extra" "$CONFIG_DIRECTORY/modules" ;;
        "4") for mod in cache search extra; do
                cp -r "$SCRIPT_DIR/modules/$mod" "$CONFIG_DIRECTORY/modules/" 2>/dev/null
        done ;;
        "5") echo "  [>>]" ;;
        *) echo "module not found."; exit 1 ;;
    esac
    step "Configuring completions"
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
        success "Fish completions configuradas."
    fi
    chown -R "$REAL_USER:$REAL_USER" "$CONFIG_DIRECTORY"
    success "Ajusted permissions."
    echo -e "\n${G}${B}Done!${NC} Jay installed successfully."
    read -n1 -s -p "Press any key to back..."
}

run_remove() {
    title
    echo -e "${R}${B}Removing JAY...${NC}\n"
    rm -f "$INSTALL_PATH"
    rm -f "/usr/share/fish/vendor_completions.d/jay.fish"
    rm -rf "$CONFIG_DIRECTORY"
    success "Removed files"
    echo -e "\n${Y}System clear.${NC}"
    read -n1 -s -p "Press any key to back..."
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
        1) new_installer ;;
        2) run_remove ;;
        3) echo -e "${C}Até logo!${NC}"; exit 0 ;;
        *) echo -e "${R}Opção inválida.${NC}"; sleep 0.5 ;;
    esac
done
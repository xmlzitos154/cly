#!/bin/bash

# --- Configurações de Cores ---
G='\e[32m' # Verde
C='\e[36m' # Ciano
Y='\e[33m' # Amarelo
R='\e[31m' # Vermelho
B='\e[1m'  # Negrito
NC='\e[0m' # Reset

# --- Extração Cirúrgica da Versão ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/main"

if [[ -f "$SOURCE" ]]; then
    VER_LINE=$(grep -m 1 "^VER=" "$SOURCE")
    if [[ -n "$VER_LINE" ]]; then
        eval "$VER_LINE"
    else
        VER="unk"
    fi
else
    echo -e "${R}Erro: Arquivo 'main' não encontrado.${NC}"
    exit 1
fi

BIN_NAME="jay"
INSTALL_PATH="/usr/bin/$BIN_NAME"

# --- Root Check ---
[[ $EUID -ne 0 ]] && { echo -e "${Y}>>${NC} Solicitando root..."; exec sudo "$0" "$@"; }

# --- Funções de Interface ---

title() {
    clear
    echo -e "${C}${B}JAY SETUP${NC} — v$VER"
    echo -e "${C}──────────────────────────────${NC}"
}

step() {
    echo -e "${C}  [..]${NC} $1"
    sleep 0.3
}

success() {
    echo -e "${G}  [OK]${NC} $1"
}

# --- Lógica de Instalação ---

run_installer() {
    title
    echo -e "${B}Instalando JAY no sistema...${NC}\n"
    
    step "Copiando binário para $INSTALL_PATH"
    install -Dm755 "$SOURCE" "$INSTALL_PATH" && success "Binário instalado"
    
    step "Configurando completions"
    
    # Fish
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
        success "Fish completions (orphan adicionado)"
    fi

    echo -e "\n${G}${B}Pronto!${NC} O jay foi atualizado."
    read -n1 -s -p "Pressione qualquer tecla para voltar..."
    exit 0
}

run_remove() {
    title
    echo -e "${R}${B}Removendo JAY...${NC}\n"
    rm -f "$INSTALL_PATH"
    rm -f "/usr/share/fish/vendor_completions.d/jay.fish"
    success "Arquivos removidos"
    echo -e "\n${Y}Sistema limpo.${NC}"
    read -n1 -s -p "Pressione qualquer tecla para voltar..."
    exit 0
}

# --- Menu ---
while true; do
    title
    echo -e "  ${C}1.${NC} Instalar / Atualizar"
    echo -e "  ${C}2.${NC} Remover"
    echo -e "  ${C}3.${NC} Sair"
    echo ""
    read -p " > " DO
    
    case "$DO" in
        1) run_installer ;;
        2) run_remove ;;
        3) echo -e "${C}Até logo!${NC}"; exit 0 ;;
        *) echo -e "${R}Opção inválida.${NC}"; sleep 0.5 ;;
    esac
done
#!/usr/bin/env bash
G='\e[32m'; C='\e[36m'; Y='\e[33m'; R='\e[31m'; B='\e[1m'; NC='\e[0m'

REAL_USER="${SUDO_USER:-$USER}"; CONFIG_DIRECTORY="/home/$REAL_USER/.config/jay"; SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; SOURCE="$SCRIPT_DIR/main"

if [[ -f "$SOURCE" ]]; then
    VER=$(sed -n 's/^VER="\(.*\)"/\1/p' "$SOURCE" | head -1)
    [[ -z "$VER" ]] && VER="unk"
else
    echo -e "${R}Erro: Arquivo 'main' não encontrado.${NC}"
    exit 1
fi

BIN_NAME="jay"
INSTALL_PATH="/usr/bin/$BIN_NAME"

[[ $EUID -ne 0 ]] && { echo -e "${Y}>>${NC} Solicitando root..."; exec sudo "$0" "$@"; }

title() { clear; echo -e "${C}${B}JAY SETUP${NC} — v$VER"; echo -e "${C}──────────────────────────────${NC}"; }
step() { echo -e "${C}  [..]${NC} $1"; sleep 0.3; }
success() { echo -e "${G}  [OK]${NC} $1"; }

new_installer() {
    title
    step "Copiando arquivos necessários..."
    install -Dm755 "$SOURCE" "$INSTALL_PATH"
    success "Pronto."
    step "Criando pasta de configs..."
    mkdir -p "$CONFIG_DIRECTORY" || exit 1
    cd "$CONFIG_DIRECTORY" || exit 1
    step "Carregando módulos basicos..."
    [[ -d "modules" ]] && rm -rf "modules"
    mkdir "modules"
    [[ ! -f "$SCRIPT_DIR/modules/base" ]] && echo -e "${R}erro: modulo base não encontrado.${NC}" && exit 1
    [[ ! -f "$SCRIPT_DIR/modules/log" ]] && echo -e "${R}erro: modulo log não encontrado.${NC}" && exit 1
    cp -r "$SCRIPT_DIR/modules/base" "$CONFIG_DIRECTORY/modules/"
    cp -r "$SCRIPT_DIR/modules/log" "$CONFIG_DIRECTORY/modules/"
    success "Pronto."
    echo "Que modulos deseja instalar?"
    echo ""
    echo "1. cache (Limpa o cache)"
    echo "2. search (search e query do yay)"
    echo "3. extra (Varias outras funções)"
    echo "4. todos"
    echo "5. nenhum"
    echo ""
    read -p " > " MODS
    case "$MODS" in
        "1") cp -r "$SCRIPT_DIR/modules/cache" "$CONFIG_DIRECTORY/modules" ;;
        "2") cp -r "$SCRIPT_DIR/modules/search" "$CONFIG_DIRECTORY/modules" ;;
        "3") cp -r "$SCRIPT_DIR/modules/extra" "$CONFIG_DIRECTORY/modules" ;;
        "4") cp -r "$SCRIPT_DIR/modules/." "$CONFIG_DIRECTORY/modules" ;;
        "5") echo "  [>>]" ;;
        *) echo "modulo não existe." && exit 1 ;;
    esac
    step "Configurando completions"
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
    chown -R "$REAL_USER:$REAL_USER" "$CONFIG_DIRECTORY"
    success "Permissões ajustadas."
    echo -e "\n${G}${B}Pronto!${NC} O jay foi instalado."
    read -n1 -s -p "Pressione qualquer tecla para voltar..."
}

debug() { 
    title; echo -e "${Y}${B}[ DEBUG MODE ]${NC}"; echo "Ações disponíveis:"; echo "  35ab - Instalar UM módulo específico"; echo "  44aa - Reinstalar TODOS os módulos"; echo "  35a6 - Remover UM módulo específico"; echo "  s4a7 - Limpar pasta de módulos"; echo ""; read -p " >> " DBG
    case "$DBG" in
        "s4a7") rm -rf "$CONFIG_DIRECTORY/modules/"*; success "Todos os módulos foram pro espaço." ;;
        "35ab")
            echo -e "\nQual módulo? (cache | search | extra | base | log)"
            read -p " >> " MOD_NAME
            TARGET_SRC="$SCRIPT_DIR/modules/$MOD_NAME"
            if [[ -e "$TARGET_SRC" ]]; then
                cp -r "$TARGET_SRC" "$CONFIG_DIRECTORY/modules/"
                success "Módulo '$MOD_NAME' injetado com sucesso."
            else
                echo -e "${R}Erro: '$MOD_NAME' não encontrado em $SCRIPT_DIR/modules/${NC}"
                echo -e "${Y}Tentativa de leitura: ${NC}$TARGET_SRC"
            fi
        ;;
        "44aa") step "Limpando e reinstalando tudo..."; rm -rf "$CONFIG_DIRECTORY/modules/"; mkdir -p "$CONFIG_DIRECTORY/modules/"; cp -r "$SCRIPT_DIR/modules/." "$CONFIG_DIRECTORY/modules/"; success "Full reset concluído." ;;
        "35a6") echo -e "\nRemover qual?"; read -p " >> " RM_NAME; rm -rf "$CONFIG_DIRECTORY/modules/$RM_NAME"; success "Módulo '$RM_NAME' removido. Adeus!" ;;
        *) echo -e "${R}Código de debug inválido.${NC}" ;;
    esac
    chown -R "$REAL_USER:$REAL_USER" "$CONFIG_DIRECTORY"; read -n1 -s -p "Pressione qualquer tecla para voltar..."; exit 0
}

run_remove() { title; echo -e "${R}${B}Removendo JAY...${NC}\n"; rm -f "$INSTALL_PATH"; rm -f "/usr/share/fish/vendor_completions.d/jay.fish"; rm -rf "$CONFIG_DIRECTORY"; success "Arquivos removidos"; echo -e "\n${Y}Sistema limpo.${NC}"; read -n1 -s -p "Pressione qualquer tecla para voltar..."; exit 0; }

while true; do
    title
    echo -e "  ${C}1.${NC} Instalar / Atualizar"
    echo -e "  ${C}2.${NC} Remover"
    echo -e "  ${C}3.${NC} Sair"
    echo ""
    read -p " > " DO
    
    case "$DO" in
        1) new_installer ;;
        2) run_remove ;;
        3) echo -e "${C}Até logo!${NC}"; exit 0 ;;
        "DEBUG_MODULES") debug ;;
        *) echo -e "${R}Opção inválida.${NC}"; sleep 0.5 ;;
    esac
done
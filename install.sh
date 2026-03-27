#!/bin/bash

# THIS TAG IS USED FOR RANDOM COMMITS (0001)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/main"

VER="1.3.5"
BIN_NAME="jay"
INSTALL_PATH="/usr/bin/$BIN_NAME"

if [[ $EUID -ne 0 ]]; then
    echo "Getting root acess..."
    exec sudo "$0" "$@"
fi

if ! command -v yay &> /dev/null; then
    echo "ERRO: O yay não foi encontrado."
    exit 1
fi

setup_completions() {
    echo "Configuring completions..."
    
    if [ -d "/usr/share/fish/vendor_completions.d" ]; then
        cat <<EOF > "/usr/share/fish/vendor_completions.d/jay.fish"
complete -c jay -f
complete -c jay -n "__fish_use_subcommand" -a "install remove refresh update search query cache slog clog help"
complete -c jay -n "__fish_seen_subcommand_from remove query" -a "(pacman -Qq)"
complete -c jay -n "__fish_seen_subcommand_from install search" -a "(pacman -Slq)"
EOF
        echo "[+] Fish completions: OK"
    fi

    if [ -d "/usr/share/bash-completion/completions" ]; then
        cat <<EOF > "/usr/share/bash-completion/completions/jay"
_jay_completions() {
    local cur=\${COMP_WORDS[COMP_CWORD]}
    local opts="install remove refresh update search query cache slog clog help"
    COMPREPLY=( \$(compgen -W "\${opts}" -- \${cur}) )
}
complete -F _jay_completions jay
EOF
        echo "[+] Bash completions: OK"
    fi

    if [ -d "/usr/share/zsh/site-functions" ]; then
        cat <<EOF > "/usr/share/zsh/site-functions/_jay"
#compdef jay
_arguments "1: :(install remove refresh update search query cache slog clog help)" "*: :_files"
EOF
        echo "[+] Zsh completions: OK"
    fi
}

installer() {
    clear
    echo "JAY Installer Ver: $VER"
    if [[ ! -f "$SOURCE" ]]; then
        echo "FATAL: File '$SOURCE' not found."
        exit 1
    fi
    
    echo "Installing $BIN_NAME in $INSTALL_PATH..."
    install -Dm755 "$SOURCE" "$INSTALL_PATH"
    
    if [[ $? -eq 0 ]]; then
        setup_completions
        echo -e "\n$BIN_NAME installed successfully with completions!"
    else
        echo "Error installing $BIN_NAME."
        exit 1
    fi
    
    read -p "Press any key to exit..." -n1 -s
    exit 0
}

remove() {
    clear
    echo "JAY Uninstaller Ver: $VER"
    
    echo "Removing $BIN_NAME and completions..."
    rm -f "$INSTALL_PATH"
    rm -f "/usr/share/fish/vendor_completions.d/jay.fish"
    rm -f "/usr/share/bash-completion/completions/jay"
    rm -f "/usr/share/zsh/site-functions/_jay"
    
    echo -e "\n$BIN_NAME and completions have been removed."
    read -p "Press any key to exit..." -n1 -s
    exit 0
}

while true; do
    clear
    echo "JAY Setup Tool"
    echo "----------------"
    echo "1. Install (Binary + Completions)"
    echo "2. Remove"
    echo "3. Exit"
    echo ""
    read -p "$ " DO
    
    case "$DO" in
        "1") installer ;;
        "2") remove ;;
        "3") exit 0 ;;
        *) echo "Invalid option."; sleep 1 ;;
    esac
done

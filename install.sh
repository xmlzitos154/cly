#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="$SCRIPT_DIR/main"

BIN_NAME="jay"
INSTALL_PATH="/usr/bin/$BIN_NAME"

if [[ $EUID -ne 0 ]]; then
    echo "Please run me as sudo."
    exit 1
fi
if ! command -v yay &> /dev/null; then
    echo "ERRO: O yay não foi encontrado."
    echo "Saindo com status 1 (Dependencias não encontradas.)"
    exit 1
fi

installer() {
    echo "jay Ver: 1.2.1"
    if [[ ! -f "$SOURCE" ]]; then
        echo "FATAL: File '$SOURCE' not found."
        exit 1
    fi
    
    echo "Installing $BIN_NAME in $INSTALL_PATH..."
    
    install -Dm755 "$SOURCE" "$INSTALL_PATH"
    
    if [[ $? -eq 0 ]]; then
        echo -e "\n$BIN_NAME installed successfully!"
    else
        echo "Error: $BIN_NAME not installed successfully."
        exit 1
    fi
    
    read -p "Press any key to exit..." -n1 -s
    exit 0
}

remove() {
    echo "jay Ver: 1.2."
    if [[ ! -f "$INSTALL_PATH" ]]; then
        echo "Error: $BIN_NAME not found in $INSTALL_PATH."
        exit 1
    fi
    
    echo "Removing $BIN_NAME..."
    rm "$INSTALL_PATH"
    
    if [[ $? -eq 0 ]]; then
        echo -e "\n$BIN_NAME has been removed."
    else
        echo "Error removing $BIN_NAME."
    fi
    
    read -p "Press any key to exit..." -n1 -s
    exit 0
}

while true; do
    clear
    echo "What do you want to do?"
    echo ""
    echo "1. Install"
    echo "2. Remove"
    echo "3. Exit"
    echo ""
    read -p "$ " DO
    
    case "$DO" in
        "1") installer ;;
        "2") remove ;;
        "3")
            echo "Exiting..."
            exit 0
        ;;
        *)
            echo "Command does not exist."
            read -p "Press [Enter] to continue."
        ;;
    esac
done

#!/bin/bash
# ============================================================
#  TTK (The Taquito Kit) v2.0 - One-Line Installer
# ============================================================
set -e

REPO="TaquitoSuabe/TTK"
BINARY="ttk-installer_linux_amd64"
DEST="/tmp/ttk-installer"

# Cleanup al salir
trap 'rm -f "$DEST"' EXIT INT TERM

# Colores TTK
CYAN='\033[38;5;36m'
GREEN='\033[38;5;46m'
RED='\033[38;5;196m'
RESET='\033[0m'

echo -e "${CYAN}[TTK] Preparando Instalador de Suite TTK v2.0...${RESET}"

# Si existe un binario local en el entorno de desarrollo/pruebas, usarlo
if [ -f "./build_output/ttk-installer_linux_amd64" ]; then
    echo -e "${CYAN}[TTK] Usando instalador local de build_output...${RESET}"
    cp "./build_output/ttk-installer_linux_amd64" "$DEST"
    chmod +x "$DEST"
elif [ -f "./ttk-installer" ]; then
    echo -e "${CYAN}[TTK] Usando instalador local...${RESET}"
    cp "./ttk-installer" "$DEST"
    chmod +x "$DEST"
else
    # Descargar la última versión desde GitHub Releases
    echo -e "${CYAN}[TTK] Descargando última versión de GitHub...${RESET}"
    URL="https://github.com/$REPO/releases/latest/download/$BINARY"
    if ! curl -sL --fail "$URL" -o "$DEST"; then
        echo -e "${RED}[TTK] Error: No se pudo descargar el instalador desde $URL${RESET}"
        exit 1
    fi
    chmod +x "$DEST"
fi

# Reconectar stdin a /dev/tty si se ejecuta a través de curl | bash
if [ ! -t 0 ] && [ -c /dev/tty ]; then
    exec < /dev/tty
fi

echo -e "${CYAN}[TTK] Iniciando interfaz del instalador...${RESET}"

# Ejecutar con permisos de root requeridos
if [ "$EUID" -ne 0 ]; then
    sudo "$DEST"
else
    "$DEST"
fi

# Post-instalación: Lanzar menú principal si TTK está instalado
if command -v ttk &> /dev/null; then
    echo -e "${GREEN}[TTK] Instalación finalizada con éxito. Iniciando TTK...${RESET}"
    sleep 1
    if [ -t 0 ]; then
        ttk
    elif [ -c /dev/tty ]; then
        exec < /dev/tty
        ttk
    fi
else
    echo -e "${RED}[TTK] Aviso: 'ttk' no fue encontrado en /usr/local/bin o PATH.${RESET}"
fi


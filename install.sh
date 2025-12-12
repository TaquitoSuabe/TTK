#!/bin/bash
# TTK One-Line Installer
set -e

REPO="TaquitoSuabe/TTK"
BINARY="ttk-installer_linux_amd64"
DEST="/tmp/ttk-installer"

# Cleanup on exit or error
trap 'rm -f "$DEST"' EXIT INT TERM

echo -e "\033[0;32m[TTK] Downloading Installer...\033[0m"

# Download from latest release
URL="https://github.com/$REPO/releases/latest/download/$BINARY"
curl -sL "$URL" -o "$DEST"
chmod +x "$DEST"

echo -e "\033[0;32m[TTK] Starting Installer...\033[0m"

# Run installer with appropriate privileges
if [ "$EUID" -ne 0 ]; then
  sudo "$DEST"
else
  "$DEST"
fi

# Post-Install Cleanup & Launch
echo -e "\033[0;32m[TTK] Limpiando instalador...\033[0m"

if command -v ttk &> /dev/null; then
    echo -e "\033[0;32m[TTK] Iniciando Menú...\033[0m"
    sleep 1
    exec < /dev/tty
    ttk
else
    echo -e "\033[0;31m[TTK] Warning: 'ttk' no encontrado en PATH. Reinicia tu sesión o ejecutalo manualmente.\033[0m"
fi

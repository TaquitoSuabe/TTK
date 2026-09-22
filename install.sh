#!/bin/bash
# ============================================================
#  TTK (The Taquito Kit) v0.2.2 - One-Line Installer
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

echo -e "${CYAN}[TTK] Preparando Instalador de Suite TTK v0.2.2...${RESET}"

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
    sudo "$DEST" "$@"
else
    "$DEST" "$@"
fi

# Configurar banner de bienvenida en .bashrc si no existe
setup_bashrc_banner() {
    local BASHRC="/root/.bashrc"
    [ -f "$BASHRC" ] || BASHRC="$HOME/.bashrc"
    if [ -f "$BASHRC" ] && ! grep -q "TTK LOGIN BANNER" "$BASHRC"; then
        cat << 'EOF' >> "$BASHRC"

# >>> TTK LOGIN BANNER >>>
if [ -t 1 ] && [ -z "$TTK_BANNER_SHOWN" ] && command -v ttk &> /dev/null; then
    export TTK_BANNER_SHOWN=1
    echo -e "
\033[38;5;208m┌── THE TAQUITO KIT ───────────────────────────────────┐\033[0m
\033[38;5;208m│\033[0m                                                      \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m            \033[1;38;5;208m████████╗  ████████╗  ██╗  ██╗\033[0m            \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m            \033[1;38;5;208m╚══██╔══╝  ╚══██╔══╝  ██║ ██╔╝\033[0m            \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m            \033[1;38;5;208m   ██║        ██║     █████╔╝ \033[0m            \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m            \033[1;38;5;208m   ██║        ██║     ██╔═██╗ \033[0m            \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m            \033[1;38;5;208m   ██║        ██║     ██║  ██╗\033[0m            \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m            \033[1;38;5;208m   ╚═╝        ╚═╝     ╚═╝  ╚═╝\033[0m            \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m                                                      \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m  Bienvenido a tu servidor VPS administrado con TTK.  \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m                                                      \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m       Para abrir el menú de control y túneles:       \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m                    ➜ \033[1;37mEscribe:\033[0m \033[1;38;5;46mttk\033[0m                    \033[38;5;208m│\033[0m
\033[38;5;208m│\033[0m                                                      \033[38;5;208m│\033[0m
\033[38;5;208m└──────────────────────────────────────────────────────┘\033[0m
"
fi
# <<< TTK LOGIN BANNER <<<
EOF
    fi
}

remove_bashrc_banner() {
    local targets=("/root/.bashrc" "/etc/bash.bashrc")
    [ -n "$HOME" ] && targets+=("$HOME/.bashrc")
    for f in "${targets[@]}"; do
        if [ -f "$f" ] && grep -q "TTK LOGIN BANNER" "$f"; then
            sed -i '/# >>> TTK LOGIN BANNER >>>/,/# <<< TTK LOGIN BANNER <<</d' "$f"
        fi
    done
    rm -f /etc/profile.d/ttk-banner.sh /etc/profile.d/ttk.sh
}

if [[ "$*" == *uninstall* ]]; then
    remove_bashrc_banner
else
    setup_bashrc_banner
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


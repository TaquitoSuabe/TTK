#!/bin/bash
# ============================================================
#  TTK (The Taquito Kit) v0.2.7 - One-Line Installer
# ============================================================
set -e

main() {
    REPO="TaquitoSuabe/TTK"

    # Detectar Arquitectura
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64)          TARGET_ARCH="amd64" ;;
        aarch64|arm64)   TARGET_ARCH="arm64" ;;
        *) 
            echo -e "\033[38;5;196m[TTK] Error: Arquitectura $ARCH no soportada.\033[0m"
            exit 1
            ;;
    esac

    BINARY="ttk-installer_linux_${TARGET_ARCH}"
    DEST="/tmp/ttk-installer"

    # Detección de Canal Testing
    IS_TESTING=false
    RELEASE_TAG="latest"
    BRANCH="main"

    for arg in "$@"; do
        if [ "$arg" == "--testing" ] || [ "$arg" == "-testing" ] || [ "$arg" == "--test" ] || [ "$arg" == "--dev" ]; then
            IS_TESTING=true
            RELEASE_TAG="testing"
            BRANCH="testing"
        fi
    done

    # Cleanup al salir
    trap 'rm -f "$DEST"' EXIT INT TERM

    # Colores TTK
    CYAN='\033[38;5;36m'
    GREEN='\033[38;5;46m'
    RED='\033[38;5;196m'
    YELLOW='\033[38;5;208m'
    RESET='\033[0m'

    if [ "$IS_TESTING" = true ]; then
        echo -e "${YELLOW}[TTK] ⚠ MODO TESTING ACTIVADO (Canal: $RELEASE_TAG / Rama: $BRANCH / Arch: $TARGET_ARCH)${RESET}"
    else
        echo -e "${CYAN}[TTK] Preparando Instalador de Suite TTK ($TARGET_ARCH)...${RESET}"
    fi

    # Si existe un binario local en el entorno de desarrollo/pruebas, usarlo
    if [ -f "./build_output/$BINARY" ]; then
        echo -e "${CYAN}[TTK] Usando instalador local de build_output...${RESET}"
        cp "./build_output/$BINARY" "$DEST"
        chmod +x "$DEST"
    elif [ -f "./$BINARY" ]; then
        echo -e "${CYAN}[TTK] Usando instalador local...${RESET}"
        cp "./$BINARY" "$DEST"
        chmod +x "$DEST"
    elif [ -f "./ttk-installer" ]; then
        echo -e "${CYAN}[TTK] Usando instalador local...${RESET}"
        cp "./ttk-installer" "$DEST"
        chmod +x "$DEST"
    else
        # Descargar desde GitHub Releases (o rama testing)
        echo -e "${CYAN}[TTK] Descargando instalador ($TARGET_ARCH) de GitHub ($RELEASE_TAG)...${RESET}"
        if [ "$RELEASE_TAG" == "latest" ]; then
            URL="https://github.com/$REPO/releases/latest/download/$BINARY"
        else
            URL="https://github.com/$REPO/releases/download/$RELEASE_TAG/$BINARY"
        fi

        download_bin() {
            local u="$1"
            local d="$2"
            if command -v curl &>/dev/null; then
                if curl -4 -fL --progress-bar --connect-timeout 15 "$u" -o "$d"; then
                    return 0
                fi
            fi
            if command -v wget &>/dev/null; then
                if wget -4 -q --show-progress --timeout=15 "$u" -O "$d"; then
                    return 0
                fi
            fi
            return 1
        }

        if ! download_bin "$URL" "$DEST"; then
            echo -e "${RED}[TTK] Error: No se pudo descargar el instalador desde $URL${RESET}"
            exit 1
        fi
        chmod +x "$DEST"
    fi

    echo -e "${CYAN}[TTK] Iniciando interfaz del instalador...${RESET}"

    # Detectar si hay una terminal TTY disponible para entrada
    HAS_TTY=false
    if (exec < /dev/tty) 2>/dev/null; then
        HAS_TTY=true
    fi

    EXTRA_ARGS=()
    if [ "$HAS_TTY" = false ]; then
        # En modo sin terminal interactiva, si no se especificó --install ni --uninstall,
        # autoejecutar --install para evitar fallas con Bubbletea TUI.
        if [[ ! "$*" =~ "--install" ]] && [[ ! "$*" =~ "-install" ]] && [[ ! "$*" =~ "--uninstall" ]] && [[ ! "$*" =~ "-uninstall" ]]; then
            EXTRA_ARGS+=("--install")
        fi
    fi

    # Ejecutar con permisos de root requeridos
    if [ "$HAS_TTY" = true ]; then
        if [ "$EUID" -ne 0 ]; then
            sudo "$DEST" "${EXTRA_ARGS[@]}" "$@" < /dev/tty
        else
            "$DEST" "${EXTRA_ARGS[@]}" "$@" < /dev/tty
        fi
    else
        if [ "$EUID" -ne 0 ]; then
            sudo "$DEST" "${EXTRA_ARGS[@]}" "$@"
        else
            "$DEST" "${EXTRA_ARGS[@]}" "$@"
        fi
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
        echo -e "${GREEN}[TTK] Instalación finalizada con éxito.${RESET}"
        if [ "$HAS_TTY" = true ]; then
            echo -e "${CYAN}[TTK] Iniciando TTK...${RESET}"
            sleep 1
            ttk < /dev/tty
        else
            echo -e "${CYAN}[TTK] Escribe 'ttk' para iniciar el menú principal.${RESET}"
        fi
    else
        echo -e "${RED}[TTK] Aviso: 'ttk' no fue encontrado en /usr/local/bin o PATH.${RESET}"
    fi
}

main "$@"


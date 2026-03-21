#!/usr/bin/env bash

# Script para seleccionar un directorio de Terraform de forma interactiva

set -uo pipefail

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Directorios de Terraform (debe coincidir con TERRAFORM_DIRS en Makefile)
readonly TERRAFORM_DIRS=(
    "shared-infra/environments/development"
    "shared-infra/environments/qa"
    "shared-infra/environments/staging"
    "shared-infra/environments/production"
    "bootstrap/global"
)

# Función para mostrar el menú
show_menu() {
    local action=$1

    # Mostrar en stderr para que no se capture en la variable cuando se ejecuta desde make
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
    echo -e "${BLUE}Selecciona un directorio para ${action}:${NC}" >&2
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
    echo "" >&2

    local index=1
    for dir in "${TERRAFORM_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            echo -e "  ${GREEN}${index}${NC}) ${dir}" >&2
        else
            echo -e "  ${RED}${index}${NC}) ${dir} ${YELLOW}(no existe)${NC}" >&2
        fi
        ((index++))
    done

    echo "" >&2
    echo -e "  ${YELLOW}0${NC}) Cancelar" >&2
    echo "" >&2
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}" >&2
}

# Función principal
main() {
    local action=${1:-"ejecutar"}
    local terraform_command=${2:-""}
    local selected_dir=""

    # Mostrar menú (siempre en stderr para que se vea)
    show_menu "$action" >&2

    # Leer selección desde /dev/tty si está disponible, sino desde stdin
    echo -ne "${YELLOW}Selecciona una opción [0-${#TERRAFORM_DIRS[@]}]: ${NC}" >&2
    if [ -t 0 ] && [ -c /dev/tty ]; then
        # stdin es un terminal y /dev/tty existe, leer desde /dev/tty
        read -r selection < /dev/tty
    else
        # Leer desde stdin (para casos donde se ejecuta desde make)
        read -r selection
    fi

    # Validar entrada
    if ! [[ "$selection" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Debes ingresar un número${NC}" >&2
        exit 1
    fi

    if [ "$selection" -eq 0 ]; then
        echo -e "${YELLOW}Operación cancelada${NC}" >&2
        exit 0
    fi

    if [ "$selection" -lt 1 ] || [ "$selection" -gt "${#TERRAFORM_DIRS[@]}" ]; then
        echo -e "${RED}Error: Opción inválida${NC}" >&2
        exit 1
    fi

    # Obtener directorio seleccionado (índice 0-based)
    selected_dir="${TERRAFORM_DIRS[$((selection - 1))]}"

    # Verificar que el directorio existe
    if [ ! -d "$selected_dir" ]; then
        echo -e "${RED}Error: El directorio '$selected_dir' no existe${NC}" >&2
        exit 1
    fi

    # Si se proporciona un comando terraform, ejecutarlo; sino, solo retornar el directorio
    if [ -n "$terraform_command" ]; then
        echo "" >&2
        echo "Ejecutando $terraform_command en: $selected_dir" >&2
        echo "" >&2
        cd "$selected_dir" && terraform $terraform_command
    else
        # Retornar el directorio seleccionado (solo stdout, sin stderr)
        echo "$selected_dir"
    fi
}

# Ejecutar función principal
main "$@"

#!/usr/bin/env bash

# Script para verificar versiones más recientes de Terraform y providers
# Este script solo informa sobre versiones disponibles, no actualiza nada
#
# Requisitos:
#   - curl
#   - grep
#   - sed
#   - sort

set -uo pipefail

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# Timeout para requests HTTP (segundos)
readonly CURL_TIMEOUT=10

# Función para verificar dependencias
check_dependencies() {
    local missing_deps=()
    local deps=("curl" "grep" "sed" "sort")

    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}Error: Faltan las siguientes dependencias:${NC}" >&2
        printf '  - %s\n' "${missing_deps[@]}" >&2
        exit 1
    fi
}

# Función para hacer request HTTP con timeout
http_get() {
    local url=$1
    curl -s --max-time "$CURL_TIMEOUT" --fail-with-body "$url" 2>/dev/null || echo ""
}

# Función para validar formato de versión semántica
is_valid_version() {
    local version=$1
    # Formato: X.Y.Z donde X, Y, Z son números
    [[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# Función para obtener la versión más reciente de Terraform
get_latest_terraform_version() {
    local latest_version=""
    local response

    # Intentar obtener desde GitHub releases API
    response=$(http_get "https://api.github.com/repos/hashicorp/terraform/releases/latest")
    if [ -n "$response" ]; then
        latest_version=$(echo "$response" | \
            grep -oE '"tag_name":\s*"v?([0-9]+\.[0-9]+\.[0-9]+)"' | \
            grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    # Fallback: intentar desde terraform.io
    if [ -z "$latest_version" ]; then
        response=$(http_get "https://releases.hashicorp.com/terraform/")
        if [ -n "$response" ]; then
            latest_version=$(echo "$response" | \
                grep -oE 'terraform_([0-9]+\.[0-9]+\.[0-9]+)' | \
                sed 's/terraform_//' | sort -V | tail -1)
        fi
    fi

    # Validar formato
    if [ -n "$latest_version" ] && is_valid_version "$latest_version"; then
        echo "$latest_version"
    else
        echo ""
    fi
}

# Función para obtener la versión más reciente del provider de Google
get_latest_google_provider_version() {
    local latest_version=""
    local response

    # Usar Terraform Registry API
    response=$(http_get "https://registry.terraform.io/v1/providers/hashicorp/google")
    if [ -n "$response" ]; then
        latest_version=$(echo "$response" | \
            grep -oE '"version":\s*"([0-9]+\.[0-9]+\.[0-9]+)"' | \
            grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    fi

    # Fallback: intentar desde GitHub releases
    if [ -z "$latest_version" ]; then
        response=$(http_get "https://api.github.com/repos/hashicorp/terraform-provider-google/releases/latest")
        if [ -n "$response" ]; then
            latest_version=$(echo "$response" | \
                grep -oE '"tag_name":\s*"v?([0-9]+\.[0-9]+\.[0-9]+)"' | \
                grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        fi
    fi

    # Validar formato
    if [ -n "$latest_version" ] && is_valid_version "$latest_version"; then
        echo "$latest_version"
    else
        echo ""
    fi
}

# Función para extraer versión mínima de un archivo Terraform
extract_terraform_version() {
    local file=$1
    if [ -f "$file" ] && [ -r "$file" ]; then
        grep -oE 'required_version\s*=\s*">=\s*([0-9]+\.[0-9]+\.[0-9]+)' "$file" 2>/dev/null | \
            grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo ""
    fi
}

# Función para extraer versión del provider de un archivo Terraform
extract_provider_version() {
    local file=$1
    if [ -f "$file" ] && [ -r "$file" ]; then
        grep -A 2 'source.*=.*"hashicorp/google"' "$file" 2>/dev/null | \
            grep -oE 'version\s*=\s*">=\s*([0-9]+\.[0-9]+\.[0-9]+)' | \
            grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo ""
    fi
}

# Función principal
main() {
    local project_root
    local terraform_files
    local terraform_versions_found=""
    local google_provider_versions_found=""
    local files_to_update=""
    local terraform_version
    local provider_version

    # Verificar dependencias
    check_dependencies

    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Verificación de Versiones de Terraform${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Obtener versiones más recientes
    echo -e "${YELLOW}Buscando versiones más recientes...${NC}" >&2
    LATEST_TERRAFORM=$(get_latest_terraform_version)
    LATEST_GOOGLE_PROVIDER=$(get_latest_google_provider_version)

    if [ -z "$LATEST_TERRAFORM" ] || [ -z "$LATEST_GOOGLE_PROVIDER" ]; then
        echo -e "${RED}Error: No se pudieron obtener las versiones más recientes.${NC}" >&2
        echo "Verifica tu conexión a internet o intenta más tarde." >&2
        exit 1
    fi

    echo -e "${GREEN}Versión más reciente de Terraform: ${LATEST_TERRAFORM}${NC}"
    echo -e "${GREEN}Versión más reciente del provider Google: ${LATEST_GOOGLE_PROVIDER}${NC}"
    echo ""

    # Buscar archivos main.tf en el proyecto
    project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    if [ ! -d "$project_root" ]; then
        echo -e "${RED}Error: No se pudo determinar el directorio raíz del proyecto.${NC}" >&2
        exit 1
    fi

    terraform_files=$(find "$project_root" -name "main.tf" -type f 2>/dev/null)

    if [ -z "$terraform_files" ]; then
        echo -e "${YELLOW}No se encontraron archivos main.tf en el proyecto.${NC}"
        exit 0
    fi

    echo -e "${BLUE}Analizando archivos del proyecto...${NC}"
    echo ""

    # Analizar cada archivo
    while IFS= read -r file; do
        [ -z "$file" ] && continue
        [ ! -f "$file" ] && continue

        terraform_version=$(extract_terraform_version "$file")
        provider_version=$(extract_provider_version "$file")

        if [ -n "$terraform_version" ]; then
            terraform_versions_found="${terraform_versions_found}${terraform_version}\n"

            # Comparar versiones (simple: solo mostrar si hay diferencia)
            if [ "$terraform_version" != "$LATEST_TERRAFORM" ]; then
                local update_msg="${file} (Terraform: ${terraform_version} -> ${LATEST_TERRAFORM})"
                files_to_update="${files_to_update}${update_msg}\n"
            fi
        fi

        if [ -n "$provider_version" ]; then
            google_provider_versions_found="${google_provider_versions_found}${provider_version}\n"

            # Comparar versiones (simple: solo mostrar si hay diferencia)
            if [ "$provider_version" != "$LATEST_GOOGLE_PROVIDER" ]; then
                local update_msg="${file} (Google Provider: ${provider_version} -> ${LATEST_GOOGLE_PROVIDER})"
                files_to_update="${files_to_update}${update_msg}\n"
            fi
        fi
    done <<< "$terraform_files"

    # Mostrar resumen
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Resumen de Versiones${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Versiones de Terraform encontradas
    if [ -n "$terraform_versions_found" ]; then
        local unique_terraform_versions
        unique_terraform_versions=$(echo -e "$terraform_versions_found" | sort -u | head -5)
        echo -e "${YELLOW}Versiones de Terraform en el proyecto:${NC}"
        echo -e "$unique_terraform_versions" | while IFS= read -r version; do
            [ -n "$version" ] && echo "  - >= $version"
        done
        echo ""
    fi

    # Versiones del provider encontradas
    if [ -n "$google_provider_versions_found" ]; then
        local unique_provider_versions
        unique_provider_versions=$(echo -e "$google_provider_versions_found" | sort -u | head -5)
        echo -e "${YELLOW}Versiones del provider Google en el proyecto:${NC}"
        echo -e "$unique_provider_versions" | while IFS= read -r version; do
            [ -n "$version" ] && echo "  - >= $version"
        done
        echo ""
    fi

    # Mostrar actualizaciones disponibles
    if [ -z "$files_to_update" ]; then
        echo -e "${GREEN}✓ Todas las versiones están actualizadas o son compatibles.${NC}"
        echo ""
        echo -e "${GREEN}Versión más reciente de Terraform: ${LATEST_TERRAFORM}${NC}"
        echo -e "${GREEN}Versión más reciente del provider Google: ${LATEST_GOOGLE_PROVIDER}${NC}"
    else
        echo -e "${YELLOW}⚠ Actualizaciones disponibles:${NC}"
        echo ""
        echo -e "$files_to_update" | while IFS= read -r update; do
            [ -n "$update" ] && echo -e "  ${YELLOW}→${NC} $update"
        done
        echo ""
        echo -e "${BLUE}Nota:${NC} Estas son solo recomendaciones. " \
            "Revisa los changelogs antes de actualizar:"
        local terraform_changelog="https://github.com/hashicorp/terraform/blob/main/CHANGELOG.md"
        local provider_changelog="https://github.com/hashicorp/terraform-provider-google/blob/main/CHANGELOG.md"
        echo -e "  - Terraform: ${terraform_changelog}"
        echo -e "  - Google Provider: ${provider_changelog}"
    fi

    echo ""
    echo -e "${BLUE}========================================${NC}"
}

# Ejecutar función principal
main "$@"

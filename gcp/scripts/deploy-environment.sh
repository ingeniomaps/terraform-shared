#!/usr/bin/env bash

# Script para desplegar un ambiente completo (state + shared-infra)
# Verifica estado global, configura GKE si es necesario, y despliega

set -uo pipefail

# Colores
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Directorio base
readonly PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT" || exit 1

# Ambiente
readonly ENV=${1:-""}

if [ -z "$ENV" ]; then
    echo -e "${RED}Error: Debes especificar un ambiente (dev, qa, stg, prod)${NC}" >&2
    exit 1
fi

# Validar ambiente y mapear a nombre de carpeta
case "$ENV" in
    dev)
        readonly ENV_DIR="development"
        ;;
    qa)
        readonly ENV_DIR="qa"
        ;;
    stg)
        readonly ENV_DIR="staging"
        ;;
    prod)
        readonly ENV_DIR="production"
        ;;
    *)
        echo -e "${RED}Error: Ambiente inválido. Debe ser: dev, qa, stg o prod${NC}" >&2
        exit 1
        ;;
esac

# Directorios
readonly STATE_DIR="bootstrap/global"
readonly SHARED_DIR="shared-infra/environments/${ENV_DIR}"
readonly GLOBAL_DIR="bootstrap/global"

# Función para verificar si existe terraform.tfvars
check_tfvars() {
    local dir=$1
    local env_name=$2

    if [ ! -f "$dir/terraform.tfvars" ]; then
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}⚠️  ERROR: No se encontró terraform.tfvars en $dir${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${YELLOW}Pasos para resolver:${NC}"
        echo -e "  1. Copia el archivo de ejemplo:"
        echo -e "     ${BLUE}cp $dir/tfvars.example $dir/terraform.tfvars${NC}"
        echo -e "  2. Edita terraform.tfvars con tus valores"
        echo -e "  3. Asegúrate de tener configurado el archivo .env"
        echo -e "  4. Ejecuta: ${BLUE}make setup${NC} para configurar automáticamente"
        echo ""
        return 1
    fi
    return 0
}

# Función para verificar estado global
check_global_state() {
    echo -e "${BLUE}Verificando estado global...${NC}"

    cd "$GLOBAL_DIR" || return 1

    if [ ! -f "terraform.tfvars" ]; then
        echo -e "${RED}Error: No existe terraform.tfvars en $GLOBAL_DIR${NC}" >&2
        echo -e "${YELLOW}   Crea el archivo manualmente y ejecuta make setup${NC}" >&2
        cd "$PROJECT_ROOT" || return 1
        return 1
    fi

    # Inicializar para verificar si el estado existe en el backend
    terraform init > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        echo -e "${YELLOW}⚠️  Error al inicializar. Verificando si necesita aplicar...${NC}"
    fi

    # Verificar si el recurso existe en el estado
    if terraform state list > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Estado global existe${NC}"
        cd "$PROJECT_ROOT" || return 1
        return 0
    else
        echo -e "${YELLOW}⚠️  El estado global no existe. Aplicando primero...${NC}"

        terraform apply -auto-approve
        if [ $? -ne 0 ]; then
            echo -e "${RED}Error al aplicar estado global${NC}" >&2
            cd "$PROJECT_ROOT" || return 1
            return 1
        fi

        echo -e "${GREEN}✓ Estado global aplicado${NC}"
        cd "$PROJECT_ROOT" || return 1
        return 0
    fi
}

# Función para preguntar sobre GKE (solo para stg y prod)
ask_gke() {
    local env_name=$1

    if [ "$env_name" != "stg" ] && [ "$env_name" != "prod" ]; then
        return 0
    fi

    local tfvars_file="$SHARED_DIR/terraform.tfvars"

    if [ ! -f "$tfvars_file" ]; then
        echo -e "${RED}Error: No existe terraform.tfvars en $SHARED_DIR${NC}" >&2
        return 1
    fi

    echo ""
    echo -e "${BLUE}¿Deseas habilitar GKE para ${env_name}? (s/n): ${NC}"

    # Leer desde /dev/tty si está disponible
    if [ -t 0 ] && [ -c /dev/tty ]; then
        read -r response < /dev/tty
    else
        read -r response
    fi

    if [[ "$response" =~ ^[Ss]$ ]]; then
        # Habilitar GKE
        if grep -q '^enable_gke' "$tfvars_file"; then
            sed -i 's/^enable_gke\s*=\s*false/enable_gke = true/' "$tfvars_file"
        else
            # Agregar si no existe
            echo "enable_gke = true" >> "$tfvars_file"
        fi

        echo -e "${GREEN}✓ GKE habilitado para ${env_name}${NC}"
        return 0
    else
        # Asegurar que esté deshabilitado
        if grep -q '^enable_gke' "$tfvars_file"; then
            sed -i 's/^enable_gke\s*=\s*true/enable_gke = false/' "$tfvars_file"
        fi
        echo -e "${YELLOW}GKE no habilitado${NC}"
        return 0
    fi
}

# Función para desplegar un directorio
deploy_dir() {
    local dir=$1
    local name=$2

    if [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Directorio $dir no existe${NC}" >&2
        return 1
    fi

    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Desplegando: ${name}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    cd "$dir" || return 1

    # Inicializar
    echo -e "${YELLOW}Inicializando Terraform...${NC}"
    terraform init
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error al inicializar${NC}" >&2
        cd "$PROJECT_ROOT" || return 1
        return 1
    fi

    # Plan
    echo -e "${YELLOW}Ejecutando terraform plan...${NC}"
    terraform plan
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error en el plan${NC}" >&2
        cd "$PROJECT_ROOT" || return 1
        return 1
    fi

    # Apply
    echo -e "${YELLOW}Ejecutando terraform apply...${NC}"
    terraform apply -auto-approve
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error al aplicar${NC}" >&2
        cd "$PROJECT_ROOT" || return 1
        return 1
    fi

    echo -e "${GREEN}✓ ${name} desplegado correctamente${NC}"
    cd "$PROJECT_ROOT" || return 1
    return 0
}

# Función para confirmar despliegue
confirm_deployment() {
    local env_name=$1

    echo ""
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}⚠️  CONFIRMACIÓN DE DESPLIEGUE${NC}"
    echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "Estás a punto de desplegar el ambiente: ${BLUE}${env_name}${NC}"
    echo ""
    echo -e "Esto desplegará:"
    echo -e "  • Terraform State Bucket (${STATE_DIR})"
    echo -e "  • Shared Infrastructure (${SHARED_DIR})"
    echo ""
    echo -e "${RED}¿Estás seguro de que deseas continuar? (s/n): ${NC}"

    # Leer desde /dev/tty si está disponible
    if [ -t 0 ] && [ -c /dev/tty ]; then
        read -r response < /dev/tty
    else
        read -r response
    fi

    if [[ ! "$response" =~ ^[Ss]$ ]]; then
        echo -e "${YELLOW}Despliegue cancelado${NC}"
        return 1
    fi

    return 0
}

# Función principal
main() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Despliegue del Ambiente: ${ENV}${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""

    # Verificar terraform.tfvars
    if ! check_tfvars "$STATE_DIR" "state"; then
        exit 1
    fi

    if ! check_tfvars "$SHARED_DIR" "shared-infra"; then
        exit 1
    fi

    # Verificar estado global
    if ! check_global_state; then
        exit 1
    fi

    # Preguntar sobre GKE (solo para stg y prod)
    if ! ask_gke "$ENV"; then
        exit 1
    fi

    # Confirmar despliegue
    if ! confirm_deployment "${ENV_DIR}"; then
        exit 0
    fi

    # Desplegar state
    if ! deploy_dir "$STATE_DIR" "Terraform State (${ENV})"; then
        exit 1
    fi

    # Desplegar shared-infra
    if ! deploy_dir "$SHARED_DIR" "Shared Infrastructure (${ENV})"; then
        exit 1
    fi

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}✓ Ambiente ${ENV} desplegado completamente${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Ejecutar función principal
main

#!/usr/bin/env bash

# Script para aplicar terraform apply en todos los terraform-state/environments
# Verifica primero que el bucket global existe antes de proceder

set -uo pipefail

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Archivo .env
readonly ENV_FILE=".env"
readonly GLOBAL_DIR="terraform-state/global"
readonly STATE_ENVIRONMENTS_DIR="terraform-state/environments"

# Función para mostrar ayuda
show_help() {
    cat << EOF
Uso: $0 [OPTIONS]

Aplica terraform apply en todos los terraform-state/environments/*.
Verifica primero que el bucket global existe antes de proceder.

Lee variables del archivo .env:
  - PROJECT_ID: ID del proyecto GCP
  - BUCKET_NAME: Nombre del bucket global (o BUCKET_PREFIX)
  - REGION: Región de GCP (default: us-central1)

Opciones:
  -h, --help          Mostrar esta ayuda
  -e, --env FILE      Usar archivo .env diferente (default: .env)
  -y, --yes           Aplicar sin confirmación

Ejemplo:
  $0
EOF
}

# Función para cargar variables del archivo .env
load_env_file() {
    local env_file=$1
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Error: Archivo $env_file no encontrado.${NC}" >&2
        echo -e "${YELLOW}Usa: cp .env.example $env_file${NC}" >&2
        exit 1
    fi

    # Cargar variables del .env
    set -a
    source "$env_file"
    set +a
}

# Función para validar variables requeridas
validate_variables() {
    local missing_vars=()

    # Verificar PROJECT_ID
    if [ -z "${PROJECT_ID:-}" ]; then
        missing_vars+=("PROJECT_ID")
    fi

    # Verificar BUCKET_NAME (puede venir de BUCKET_PREFIX o BUCKET_NAME)
    if [ -z "${BUCKET_NAME:-}" ]; then
        if [ -z "${BUCKET_PREFIX:-}" ]; then
            missing_vars+=("BUCKET_NAME o BUCKET_PREFIX")
        else
            # Si no hay BUCKET_NAME pero hay BUCKET_PREFIX, usar BUCKET_PREFIX
            export BUCKET_NAME="${BUCKET_PREFIX}"
        fi
    fi

    # REGION es opcional (default: us-central1)
    export REGION="${REGION:-us-central1}"

    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${RED}Error: Faltan las siguientes variables en .env:${NC}" >&2
        printf '  - %s\n' "${missing_vars[@]}" >&2
        exit 1
    fi
}

# Función para verificar si el bucket existe
check_bucket_exists() {
    local bucket_name=$1
    local project_id=$2

    if gcloud storage buckets describe "gs://${bucket_name}" \
        --project="${project_id}" > /dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# Función para verificar que el global existe
check_global_bucket() {
    echo -e "${BLUE}Verificando que el bucket global existe...${NC}"

    if check_bucket_exists "$BUCKET_NAME" "$PROJECT_ID"; then
        echo -e "${GREEN}✓ Bucket global '${BUCKET_NAME}' encontrado${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ El bucket global '${BUCKET_NAME}' NO existe${NC}"
        echo ""
        echo -e "${YELLOW}⚠️  IMPORTANTE: El bucket global debe existir antes de aplicar los environments${NC}"
        echo ""
        echo -e "${CYAN}Para crear el bucket global, ejecuta:${NC}"
        echo -e "  ${YELLOW}make recover-global${NC}"
        echo -e "  ${YELLOW}o${NC}"
        echo -e "  ${YELLOW}cd ${GLOBAL_DIR} && terraform init && terraform apply${NC}"
        echo ""
        echo -e "${CYAN}El bucket global es necesario porque los environments lo usan como backend.${NC}"
        exit 1
    fi
}

# Función para aplicar terraform en un directorio
apply_directory() {
    local dir=$1
    local env_name
    env_name=$(basename "$dir")

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Aplicando: ${env_name}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ ! -d "$dir" ]; then
        echo -e "${YELLOW}⚠ Directorio $dir no existe, saltando...${NC}"
        return 1
    fi

    if [ ! -f "$dir/main.tf" ]; then
        echo -e "${YELLOW}⚠ main.tf no existe en $dir, saltando...${NC}"
        return 1
    fi

    # Inicializar si es necesario
    if [ ! -d "$dir/.terraform" ]; then
        echo -e "${BLUE}Inicializando Terraform...${NC}"
        if ! (cd "$dir" && terraform init); then
            echo -e "${RED}✗ Error al inicializar Terraform en $dir${NC}" >&2
            return 1
        fi
    fi

    # Aplicar
    echo -e "${BLUE}Aplicando cambios...${NC}"
    if (cd "$dir" && terraform apply); then
        echo -e "${GREEN}✓ $env_name aplicado exitosamente${NC}"
        echo ""
        return 0
    else
        echo -e "${RED}✗ Error al aplicar $env_name${NC}" >&2
        echo ""
        return 1
    fi
}

# Función principal
main() {
    local env_file="$ENV_FILE"
    local auto_confirm=false

    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -e|--env)
                env_file="$2"
                shift 2
                ;;
            -y|--yes)
                auto_confirm=true
                shift
                ;;
            *)
                echo -e "${RED}Error: Opción desconocida: $1${NC}" >&2
                show_help
                exit 1
                ;;
        esac
    done

    echo -e "${BLUE}=== Aplicar Terraform State Environments ===${NC}"
    echo ""

    # Cargar variables del .env
    echo -e "${BLUE}Cargando variables de ${env_file}...${NC}"
    load_env_file "$env_file"
    validate_variables

    echo -e "${GREEN}✓ Variables cargadas:${NC}"
    echo -e "  PROJECT_ID: ${PROJECT_ID}"
    echo -e "  BUCKET_NAME: ${BUCKET_NAME}"
    echo -e "  REGION: ${REGION}"
    echo ""

    # Verificar que el bucket global existe
    if ! check_global_bucket; then
        exit 1
    fi

    # Verificar que el directorio de environments existe
    if [ ! -d "$STATE_ENVIRONMENTS_DIR" ]; then
        echo -e "${RED}Error: Directorio ${STATE_ENVIRONMENTS_DIR} no encontrado${NC}" >&2
        exit 1
    fi

    # Confirmar antes de proceder
    if [ "$auto_confirm" = "false" ]; then
        echo -e "${YELLOW}Se aplicará terraform apply en todos los environments:${NC}"
        for env_dir in "$STATE_ENVIRONMENTS_DIR"/*; do
            if [ -d "$env_dir" ]; then
                echo -e "  - $(basename "$env_dir")"
            fi
        done
        echo ""
        echo -e "${CYAN}¿Deseas continuar? (s/N)${NC}"
        read -r response || response="N"
        if [[ ! "$response" =~ ^[sS]$ ]]; then
            echo -e "${YELLOW}Operación cancelada${NC}"
            exit 0
        fi
        echo ""
    fi

    # Aplicar en cada environment
    local success_count=0
    local fail_count=0
    local total_count=0

    for env_dir in "$STATE_ENVIRONMENTS_DIR"/*; do
        if [ -d "$env_dir" ]; then
            total_count=$((total_count + 1))
            if apply_directory "$env_dir"; then
                success_count=$((success_count + 1))
            else
                fail_count=$((fail_count + 1))
            fi
        fi
    done

    # Resumen
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}Resumen:${NC}"
    echo -e "  Total: ${total_count}"
    echo -e "  ${GREEN}Exitosos: ${success_count}${NC}"
    if [ $fail_count -gt 0 ]; then
        echo -e "  ${RED}Fallidos: ${fail_count}${NC}"
    fi
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

    if [ $fail_count -gt 0 ]; then
        exit 1
    fi
}

# Ejecutar función principal
main "$@"

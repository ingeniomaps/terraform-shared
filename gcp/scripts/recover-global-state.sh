#!/usr/bin/env bash

# Script para recuperar el estado de Terraform del módulo global
# Lee variables del archivo .env y importa el recurso si existe en GCP

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

# Función para mostrar ayuda
show_help() {
    cat << EOF
Uso: $0 [OPTIONS]

Recupera el estado de Terraform del módulo global importando el bucket
desde GCP si existe.

Lee variables del archivo .env:
  - PROJECT_ID: ID del proyecto GCP
  - BUCKET_NAME: Nombre del bucket global (o BUCKET_PREFIX)
  - REGION: Región de GCP (default: us-central1)

Opciones:
  -h, --help          Mostrar esta ayuda
  -e, --env FILE      Usar archivo .env diferente (default: .env)

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

    echo -e "${BLUE}Verificando si el bucket existe en GCP...${NC}"

    # Método 1: Intentar con gcloud storage buckets describe
    if gcloud storage buckets describe "gs://${bucket_name}" \
        --project="${project_id}" > /dev/null 2>&1; then
        return 0
    fi

    # Método 2: Intentar con gcloud storage buckets list (más robusto)
    if gcloud storage buckets list \
        --project="${project_id}" \
        --filter="name:${bucket_name}" \
        --format="value(name)" 2>/dev/null | grep -q "^${bucket_name}$"; then
        return 0
    fi

    # Método 3: Verificar usando terraform state si existe
    local global_dir="$GLOBAL_DIR"
    if [ -f "${global_dir}/terraform.tfstate" ]; then
        if terraform state list -state="${global_dir}/terraform.tfstate" 2>/dev/null | grep -q "module.terraform_state_bucket.google_storage_bucket.bucket_protected"; then
            echo -e "${YELLOW}⚠ No se pudo verificar con gcloud, pero el estado local indica que el bucket existe${NC}"
            return 0
        fi
    fi

    # Si llegamos aquí, mostrar el error real de gcloud
    echo -e "${YELLOW}⚠ Error al verificar bucket con gcloud. Verificando con método alternativo...${NC}"
    local error_output
    error_output=$(gcloud storage buckets describe "gs://${bucket_name}" \
        --project="${project_id}" 2>&1)
    local exit_code=$?

    # Si el error es de autenticación, sugerir solución
    if echo "$error_output" | grep -q "auth\|login\|credentials"; then
        echo -e "${YELLOW}⚠ Problema de autenticación con gcloud${NC}"
        echo -e "${CYAN}Ejecuta: gcloud auth login${NC}"
    fi

    return 1
}

# Función para importar el recurso
import_resource() {
    local bucket_name=$1
    local global_dir=$2

    echo -e "${BLUE}Inicializando Terraform (sin backend)...${NC}"
    if ! (cd "$global_dir" && terraform init -backend=false > /dev/null 2>&1); then
        echo -e "${RED}✗ Error al inicializar Terraform${NC}" >&2
        return 1
    fi

    echo -e "${BLUE}Importando recurso...${NC}"
    local resource_id="module.terraform_state_bucket.google_storage_bucket.bucket_protected[0]"
    local resource_name="${bucket_name}"

    if (cd "$global_dir" && \
        terraform import "$resource_id" "$resource_name" 2>&1); then
        echo -e "${GREEN}✓ Recurso importado exitosamente${NC}"
        echo ""
        echo -e "${CYAN}Estado recuperado en: ${global_dir}/terraform.tfstate${NC}"
        echo -e "${CYAN}Puedes verificar el estado con:${NC}"
        echo -e "  ${YELLOW}cd ${global_dir} && terraform state list${NC}"
        return 0
    else
        echo -e "${RED}✗ Error al importar el recurso${NC}" >&2
        return 1
    fi
}

# Función principal
main() {
    local env_file="$ENV_FILE"

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
            *)
                echo -e "${RED}Error: Opción desconocida: $1${NC}" >&2
                show_help
                exit 1
                ;;
        esac
    done

    echo -e "${BLUE}=== Recuperación de Estado del Módulo Global ===${NC}"
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

    # Verificar que el directorio global existe
    if [ ! -d "$GLOBAL_DIR" ]; then
        echo -e "${RED}Error: Directorio ${GLOBAL_DIR} no encontrado${NC}" >&2
        exit 1
    fi

    # Verificar primero si terraform ya tiene el estado (método más confiable)
    local state_exists=false
    if [ -f "${GLOBAL_DIR}/terraform.tfstate" ]; then
        if terraform state list -state="${GLOBAL_DIR}/terraform.tfstate" 2>/dev/null | grep -q "module.terraform_state_bucket.google_storage_bucket.bucket_protected"; then
            echo -e "${GREEN}✓ Estado de Terraform encontrado localmente${NC}"
            echo -e "${CYAN}El bucket ya está en el estado de Terraform.${NC}"
            echo ""
            echo -e "${CYAN}Si necesitas verificar el estado actual, ejecuta:${NC}"
            echo -e "  ${YELLOW}cd ${GLOBAL_DIR} && terraform refresh${NC}"
            echo ""
            exit 0
        fi
    fi

    # Si terraform tiene backend configurado, intentar refrescar el estado
    if [ -f "${GLOBAL_DIR}/.terraform/terraform.tfstate" ] || [ -f "${GLOBAL_DIR}/terraform.tfstate.backup" ]; then
        echo -e "${BLUE}Intentando refrescar estado desde backend...${NC}"
        if (cd "$GLOBAL_DIR" && terraform init > /dev/null 2>&1 && terraform state list 2>/dev/null | grep -q "module.terraform_state_bucket.google_storage_bucket.bucket_protected"); then
            echo -e "${GREEN}✓ Estado encontrado en backend de Terraform${NC}"
            echo -e "${CYAN}El bucket ya está gestionado por Terraform.${NC}"
            echo ""
            exit 0
        fi
    fi

    # Si no hay estado, verificar con gcloud si el bucket existe
    if ! check_bucket_exists "$BUCKET_NAME" "$PROJECT_ID"; then
        echo -e "${YELLOW}⚠ El bucket global '${BUCKET_NAME}' NO existe en el proyecto '${PROJECT_ID}'${NC}"
        echo ""
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${RED}⚠️  IMPORTANTE: El bucket global debe ser creado primero${NC}"
        echo -e "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        echo -e "${CYAN}Este script solo puede RECUPERAR el estado si el bucket ya existe.${NC}"
        echo -e "${CYAN}Si el bucket no existe, debes CREARLO primero.${NC}"
        echo ""
        echo -e "${CYAN}Para crear el bucket global, ejecuta:${NC}"
        echo -e "  ${YELLOW}cd ${GLOBAL_DIR}${NC}"
        echo -e "  ${YELLOW}terraform init${NC}"
        echo -e "  ${YELLOW}terraform apply${NC}"
        echo ""
        echo -e "${CYAN}Posibles causas si el bucket debería existir:${NC}"
        echo -e "  1. El nombre del bucket es incorrecto"
        echo -e "  2. No tienes permisos para acceder al bucket"
        echo -e "  3. El proyecto ID es incorrecto"
        echo -e "  4. Problema de autenticación con gcloud (ejecuta: gcloud auth login)"
        echo ""
        exit 1
    fi

    echo -e "${GREEN}✓ Bucket encontrado${NC}"
    echo ""

    # Verificar si el estado ya existe
    if [ -f "${GLOBAL_DIR}/terraform.tfstate" ]; then
        echo -e "${YELLOW}⚠ Ya existe un archivo terraform.tfstate${NC}"
        echo -e "${CYAN}¿Deseas sobrescribirlo? (s/N)${NC}"
        read -r response || response="N"
        if [[ ! "$response" =~ ^[sS]$ ]]; then
            echo -e "${YELLOW}Operación cancelada${NC}"
            exit 0
        fi
    fi

    # Importar el recurso
    if import_resource "$BUCKET_NAME" "$GLOBAL_DIR"; then
        echo ""
        echo -e "${GREEN}✓ Estado recuperado exitosamente${NC}"
        echo ""
        echo -e "${CYAN}Próximos pasos:${NC}"
        echo -e "  1. Verificar el estado: ${YELLOW}cd ${GLOBAL_DIR} && terraform state list${NC}"
        echo -e "  2. Revisar diferencias: ${YELLOW}cd ${GLOBAL_DIR} && terraform plan${NC}"
        echo -e "  3. Aplicar cambios si es necesario: ${YELLOW}cd ${GLOBAL_DIR} && terraform apply${NC}"
        exit 0
    else
        echo -e "${RED}✗ Error al recuperar el estado${NC}" >&2
        exit 1
    fi
}

# Ejecutar función principal
main "$@"

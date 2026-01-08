#!/usr/bin/env bash

# Script para configurar el proyecto para un nuevo workspace/proyecto
# Lee variables de un archivo .env y reemplaza valores en los archivos relevantes

set -uo pipefail

# Colores para output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Archivo .env
readonly ENV_FILE=".env"
readonly ENV_EXAMPLE=".env.example"

# Función para mostrar ayuda
show_help() {
    cat << EOF
Uso: $0 [OPTIONS]

Configura el proyecto Terraform para un nuevo workspace/proyecto.

Lee variables del archivo .env y reemplaza valores en:
  - shared-infra/environments/*/main.tf (backend buckets)
  - shared-infra/environments/*/terraform.tfvars (generado desde tfvars.example si no existe)
  - terraform-state/environments/*/main.tf
  - terraform-state/environments/*/terraform.tfvars (generado desde tfvars.example si no existe)
  - terraform-state/environments/*/backend.tf
  - terraform-state/global/terraform.tfvars (generado desde tfvars.example si no existe)

Opciones:
  -h, --help          Mostrar esta ayuda
  -d, --dry-run       Mostrar cambios sin aplicarlos
  -e, --env FILE      Usar archivo .env diferente (default: .env)
  -v, --verbose       Mostrar información detallada

Ejemplo:
  cp .env.example .env
  # Editar .env con tus valores
  $0
EOF
}

# Función para cargar variables del archivo .env
load_env_file() {
    local env_file=$1
    if [ ! -f "$env_file" ]; then
        echo -e "${RED}Error: Archivo $env_file no encontrado.${NC}" >&2
        echo -e "${YELLOW}Usa: cp $ENV_EXAMPLE $env_file${NC}" >&2
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
    local required_vars=(
        "PROJECT_ID"
        "WORKSPACE"
        "ORGANIZATION_ID"
        "ALLOWED_DOMAINS"
        "REGISTRY_NAME"
        "BUCKET_PREFIX"
    )

    # Variables opcionales pero recomendadas (admin_groups)
    local optional_vars=(
        "NETWORK_ADMINS"
        "NETWORK_VIEWERS"
        "SECURITY_ADMINS"
        "AUDITORS"
    )

    for var in "${required_vars[@]}"; do
        if [ -z "${!var:-}" ]; then
            missing_vars+=("$var")
        fi
    done

    if [ ${#missing_vars[@]} -gt 0 ]; then
        echo -e "${RED}Error: Faltan las siguientes variables en .env:${NC}" >&2
        printf '  - %s\n' "${missing_vars[@]}" >&2
        exit 1
    fi
}

# Función para reemplazar en archivo
replace_in_file() {
    local file=$1
    local pattern=$2
    local replacement=$3
    local dry_run=${4:-false}

    if [ ! -f "$file" ]; then
        return 0  # Archivo no existe, continuar
    fi

    if [ "$dry_run" = "true" ]; then
        # En dry-run, verificar si el valor actual es diferente al nuevo
        # Convertir patrón para grep (reemplazar \s con [[:space:]] para compatibilidad)
        local grep_pattern
        grep_pattern=$(echo "$pattern" | sed 's/\\s/[[:space:]]/g')

        local current_line
        current_line=$(grep -E "$grep_pattern" "$file" 2>/dev/null | head -1)

        if [ -n "$current_line" ]; then
            # Extraer el valor actual (asumiendo formato: key = "value" o key="value")
            local current_value
            current_value=$(echo "$current_line" | sed -n 's/.*=[[:space:]]*"\([^"]*\)".*/\1/p')

            # Extraer el nuevo valor
            local new_value
            new_value=$(echo "$replacement" | sed -n 's/.*=[[:space:]]*"\([^"]*\)".*/\1/p')

            # Solo mostrar cambio si los valores son diferentes
            if [ "$current_value" != "$new_value" ]; then
                echo -e "${YELLOW}  [DRY-RUN]${NC} $file"
                echo -e "    ${BLUE}Valor actual:${NC} $current_line"
                echo -e "    ${GREEN}Valor nuevo:${NC} $replacement"
            fi
        fi
    else
        # Convertir patrón para grep (reemplazar \s con [[:space:]] para compatibilidad)
        local grep_pattern
        grep_pattern=$(echo "$pattern" | sed 's/\\s/[[:space:]]/g')

        # Verificar si el patrón existe en el archivo
        if ! grep -qE "$grep_pattern" "$file" 2>/dev/null; then
            # Patrón no encontrado - puede ser normal para algunos casos (como allowed_domains que puede no existir)
            # No mostrar error, simplemente no hacer nada
            return 0
        fi

        # Crear una copia temporal para comparar cambios
        local temp_file
        temp_file=$(mktemp)
        cp "$file" "$temp_file"

        # Convertir patrón para perl (mejor manejo de regex que sed)
        # Reemplazar \s con \s (perl lo entiende) o [[:space:]]
        local perl_pattern
        perl_pattern=$(echo "$pattern" | sed 's/\\s/\\s/g')

        # Escapar el reemplazo para perl (escapar $ y \)
        local perl_replacement
        perl_replacement=$(printf '%s\n' "$replacement" | sed 's/\\/\\\\/g' | sed 's/\$/\\$/g')

        # Intentar el reemplazo con perl (mejor soporte para regex)
        if perl -i -pe "s|$perl_pattern|$perl_replacement|g" "$temp_file" 2>/dev/null; then
            # Perl siempre retorna éxito, verificar si hubo cambios
            :
        fi

        # Comparar si hubo cambios reales
        if ! cmp -s "$file" "$temp_file"; then
            # Hubo cambios, aplicar al archivo original
            mv "$temp_file" "$file"
            echo -e "${GREEN}✓${NC} $file"
        else
            # No hubo cambios, eliminar archivo temporal
            rm -f "$temp_file"
            # No mostrar mensaje si no hay cambios
        fi
    fi
}

# Función para extraer el nombre del ambiente del directorio
get_environment_from_path() {
    local dir=$1
    # Extraer el nombre del ambiente del path (último componente del directorio)
    basename "$dir"
}

# Función para obtener el sufijo del bucket según el ambiente
get_bucket_suffix() {
    local env=$1
    case "$env" in
        development|dev)
            echo "dev"
            ;;
        qa)
            echo "qa"
            ;;
        staging|stg)
            echo "stg"
            ;;
        production|prod)
            echo "prod"
            ;;
        *)
            # Si no coincide, usar el nombre del ambiente en minúsculas
            echo "$env" | tr '[:upper:]' '[:lower:]'
            ;;
    esac
}

# Función para leer el valor de env del tfvars.example o terraform.tfvars
get_env_from_tfvars() {
    local dir=$1
    local tfvars_example="$dir/tfvars.example"
    local tfvars="$dir/terraform.tfvars"

    # Intentar leer de terraform.tfvars primero (si existe)
    if [ -f "$tfvars" ]; then
        local env_value
        # Intentar con comillas primero
        env_value=$(grep -E '^env\s*=' "$tfvars" 2>/dev/null | head -1 | sed -n 's/.*env\s*=\s*"\([^"]*\)".*/\1/p' | tr -d ' ')
        # Si no tiene comillas, leer sin comillas
        if [ -z "$env_value" ]; then
            env_value=$(grep -E '^env\s*=' "$tfvars" 2>/dev/null | head -1 | sed -n 's/.*env\s*=\s*\([^[:space:]]*\).*/\1/p' | tr -d ' ')
        fi
        if [ -n "$env_value" ]; then
            echo "$env_value"
            return 0
        fi
    fi

    # Si no está en terraform.tfvars, leer de tfvars.example
    if [ -f "$tfvars_example" ]; then
        local env_value
        # Intentar con comillas primero
        env_value=$(grep -E '^env\s*=' "$tfvars_example" 2>/dev/null | head -1 | sed -n 's/.*env\s*=\s*"\([^"]*\)".*/\1/p' | tr -d ' ')
        # Si no tiene comillas, leer sin comillas
        if [ -z "$env_value" ]; then
            env_value=$(grep -E '^env\s*=' "$tfvars_example" 2>/dev/null | head -1 | sed -n 's/.*env\s*=\s*\([^[:space:]]*\).*/\1/p' | tr -d ' ')
        fi
        if [ -n "$env_value" ]; then
            echo "$env_value"
            return 0
        fi
    fi

    # Si no se encuentra, usar el nombre del directorio como fallback
    local dir_name
    dir_name=$(basename "$dir")
    get_bucket_suffix "$dir_name"
}

# Función para procesar archivos de un directorio
process_directory() {
    local dir=$1
    local dry_run=${2:-false}
    local verbose=${3:-false}

    if [ ! -d "$dir" ]; then
        return 0
    fi

    # Extraer el ambiente del path (para logging)
    local env_name
    env_name=$(get_environment_from_path "$dir")

    # Obtener el sufijo del bucket desde el valor de env en tfvars.example
    # Esto asegura que usemos el valor correcto (dev, qa, stg, prod) en lugar del nombre del directorio
    local bucket_suffix
    bucket_suffix=$(get_env_from_tfvars "$dir")

    if [ "$verbose" = "true" ]; then
        echo -e "${BLUE}Procesando:${NC} $dir (ambiente: $env_name, sufijo: $bucket_suffix)"
    fi

    # Procesar main.tf (backend bucket)
    local main_tf="$dir/main.tf"
    if [ -f "$main_tf" ]; then
        # Reemplazar bucket en backend usando el sufijo correcto del ambiente
        local old_bucket_pattern='bucket\s*=\s*"[^"]*"'
        local new_bucket="bucket = \"${BUCKET_PREFIX}-${bucket_suffix}\""
        replace_in_file "$main_tf" "$old_bucket_pattern" "$new_bucket" "$dry_run"

        # Reemplazar prefix si incluye workspace o ambiente
        if grep -q "prefix.*workspace\|prefix.*${env_name}" "$main_tf" 2>/dev/null; then
            local old_prefix_pattern='prefix\s*=\s*"[^"]*"'
            # El prefix puede variar según el ambiente, mantener el formato existente
            # pero actualizar si incluye el ambiente
            local current_prefix
            current_prefix=$(grep -E 'prefix\s*=' "$main_tf" 2>/dev/null | head -1 | sed -n 's/.*prefix\s*=\s*"\([^"]*\)".*/\1/p')
            if [ -n "$current_prefix" ]; then
                # Si el prefix incluye el nombre del ambiente, actualizarlo
                local new_prefix="$current_prefix"
                if [[ "$current_prefix" == *"${env_name}"* ]] || [[ "$current_prefix" == *"dev"* ]] || [[ "$current_prefix" == *"stg"* ]] || [[ "$current_prefix" == *"prod"* ]] || [[ "$current_prefix" == *"qa"* ]]; then
                    # Reemplazar cualquier referencia al ambiente anterior con el nuevo
                    new_prefix=$(echo "$current_prefix" | sed "s/\(dev\|stg\|prod\|qa\|development\|staging\|production\)/${bucket_suffix}/g")
                fi
                replace_in_file "$main_tf" "$old_prefix_pattern" "prefix = \"${new_prefix}\"" "$dry_run"
            fi
        fi
    fi

    # Generar terraform.tfvars desde tfvars.example si no existe
    local tfvars="$dir/terraform.tfvars"
    local tfvars_example="$dir/tfvars.example"

    if [ ! -f "$tfvars" ] && [ -f "$tfvars_example" ]; then
        if [ "$dry_run" = "true" ]; then
            echo -e "${YELLOW}  [DRY-RUN]${NC} Generaría $tfvars desde $tfvars_example"
        else
            cp "$tfvars_example" "$tfvars"
            echo -e "${GREEN}✓${NC} Generado $tfvars desde $tfvars_example"
        fi
    fi

    # Procesar terraform.tfvars (ahora debería existir si había tfvars.example)
    if [ -f "$tfvars" ]; then
        # project_id
        replace_in_file "$tfvars" '^project_id\s*=\s*"[^"]*"' \
            "project_id = \"${PROJECT_ID}\"" "$dry_run"

        # workspace
        replace_in_file "$tfvars" '^workspace\s*=\s*"[^"]*"' \
            "workspace = \"${WORKSPACE}\"" "$dry_run"

        # organization_id
        replace_in_file "$tfvars" '^organization_id\s*=\s*"[^"]*"' \
            "organization_id = \"${ORGANIZATION_ID}\"" "$dry_run"

        # allowed_domains (array)
        if [ -n "${ALLOWED_DOMAINS:-}" ]; then
            # Convertir lista separada por comas a formato HCL array
            local domains_list=""
            IFS=',' read -ra DOMAINS <<< "$ALLOWED_DOMAINS"
            for domain in "${DOMAINS[@]}"; do
                domain=$(echo "$domain" | xargs)  # trim whitespace
                if [ -n "$domains_list" ]; then
                    domains_list="${domains_list}\n    \"${domain}\","
                else
                    domains_list="    \"${domain}\","
                fi
            done
            # Remover última coma
            domains_list=$(echo -e "$domains_list" | sed '$s/,$//')

            local old_pattern='allowed_domains\s*=\s*\[[^\]]*\]'
            local new_value="allowed_domains = [\n${domains_list}\n]"
            replace_in_file "$tfvars" "$old_pattern" "$new_value" "$dry_run"
        fi

        # registry_name
        # Para shared-infra, agregar sufijo del ambiente al registry_name
        if [ -n "${REGISTRY_NAME:-}" ]; then
            local registry_name_value="${REGISTRY_NAME}"

            # Solo agregar sufijo si estamos en shared-infra
            if [[ "$dir" == *"shared-infra"* ]]; then
                local env_suffix
                env_suffix=$(get_env_from_tfvars "$dir")
                if [ -n "$env_suffix" ]; then
                    registry_name_value="${REGISTRY_NAME}-${env_suffix}"
                fi
            fi

            replace_in_file "$tfvars" '^registry_name\s*=\s*"[^"]*"' \
                "registry_name = \"${registry_name_value}\"" "$dry_run"
        fi

        # admin_groups (objeto HCL)
        if [ -n "${NETWORK_ADMINS:-}" ] && [ -n "${NETWORK_VIEWERS:-}" ] && \
           [ -n "${SECURITY_ADMINS:-}" ] && [ -n "${AUDITORS:-}" ]; then
            local admin_groups_block="admin_groups = {\n"
            admin_groups_block="${admin_groups_block}  network_admins  = \"${NETWORK_ADMINS}\"\n"
            admin_groups_block="${admin_groups_block}  network_viewers = \"${NETWORK_VIEWERS}\"\n"
            admin_groups_block="${admin_groups_block}  security_admins = \"${SECURITY_ADMINS}\"\n"
            admin_groups_block="${admin_groups_block}  auditors        = \"${AUDITORS}\"\n"
            admin_groups_block="${admin_groups_block}}"

            # Buscar y reemplazar el bloque completo de admin_groups
            local old_pattern='admin_groups\s*=\s*\{[^}]*\}'
            replace_in_file "$tfvars" "$old_pattern" "$admin_groups_block" "$dry_run"
        fi

        # region (si está definido)
        if [ -n "${REGION:-}" ]; then
            replace_in_file "$tfvars" '^region\s*=\s*"[^"]*"' \
                "region = \"${REGION}\"" "$dry_run"
        fi
    fi

    # Procesar backend.tf (para terraform-state/environments/*)
    local backend_tf="$dir/backend.tf"
    if [ -f "$backend_tf" ]; then
        # Para terraform-state, el bucket puede ser el mismo para todos o tener sufijo
        # Verificar si el bucket actual tiene sufijo de ambiente
        local current_bucket
        current_bucket=$(grep -E 'bucket\s*=' "$backend_tf" 2>/dev/null | head -1 | sed -n 's/.*bucket\s*=\s*"\([^"]*\)".*/\1/p')
        local new_bucket="${BUCKET_PREFIX}"

        # Si el bucket actual tiene sufijo (ej: -dev, -stg), mantener el patrón
        if [[ "$current_bucket" == *"-dev" ]] || [[ "$current_bucket" == *"-qa" ]] || \
           [[ "$current_bucket" == *"-stg" ]] || [[ "$current_bucket" == *"-prod" ]]; then
            new_bucket="${BUCKET_PREFIX}-${bucket_suffix}"
        fi

        replace_in_file "$backend_tf" 'bucket\s*=\s*"[^"]*"' \
            "bucket = \"${new_bucket}\"" "$dry_run"
    fi
}

# Función principal
main() {
    local dry_run=false
    local verbose=false
    local env_file="$ENV_FILE"

    # Parsear argumentos
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -d|--dry-run)
                dry_run=true
                shift
                ;;
            -e|--env)
                env_file="$2"
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            *)
                echo -e "${RED}Error: Opción desconocida: $1${NC}" >&2
                show_help
                exit 1
                ;;
        esac
    done

    # Obtener directorio raíz del proyecto
    local project_root
    project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    cd "$project_root" || exit 1

    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}Modo DRY-RUN: No se aplicarán cambios${NC}"
        echo ""
    fi

    # Cargar variables del .env
    echo -e "${YELLOW}Cargando variables de $env_file...${NC}"
    load_env_file "$env_file"
    validate_variables

    echo -e "${GREEN}Variables cargadas correctamente${NC}"
    echo ""

    # Mostrar variables (sin valores sensibles completos)
    if [ "$verbose" = "true" ]; then
        echo -e "${BLUE}Variables configuradas:${NC}"
        echo "  PROJECT_ID: ${PROJECT_ID:0:20}..."
        echo "  WORKSPACE: $WORKSPACE"
        echo "  ORGANIZATION_ID: ${ORGANIZATION_ID:0:10}..."
        echo "  REGISTRY_NAME: ${REGISTRY_NAME:-<no definido>}"
        echo "  BUCKET_PREFIX: ${BUCKET_PREFIX:-<no definido>}"
        echo ""
    fi

    # Procesar archivos
    echo -e "${BLUE}Procesando archivos...${NC}"
    echo ""

    # Shared infrastructure - procesar todos los ambientes
    for env_dir in shared-infra/environments/*; do
        if [ -d "$env_dir" ]; then
            process_directory "$env_dir" "$dry_run" "$verbose"
        fi
    done

    # Terraform state buckets - procesar todos los ambientes
    for env_dir in terraform-state/environments/*; do
        if [ -d "$env_dir" ]; then
            process_directory "$env_dir" "$dry_run" "$verbose"
        fi
    done

    # Procesar global
    process_directory "terraform-state/global" "$dry_run" "$verbose"

    # Procesar bucket_prefix y bucket_name en terraform-state
    for dir in terraform-state/environments/* terraform-state/global; do
        if [ -d "$dir" ]; then
            local tfvars="$dir/terraform.tfvars"
            if [ -f "$tfvars" ]; then
                # bucket_prefix (para módulos que lo usan)
                if grep -q "^bucket_prefix" "$tfvars" 2>/dev/null; then
                    replace_in_file "$tfvars" '^bucket_prefix\s*=\s*"[^"]*"' \
                        "bucket_prefix = \"${BUCKET_PREFIX}\"" "$dry_run"
                fi

                # bucket_name (para terraform-state/global)
                if grep -q "^bucket_name" "$tfvars" 2>/dev/null; then
                    replace_in_file "$tfvars" '^bucket_name\s*=\s*"[^"]*"' \
                        "bucket_name = \"${BUCKET_PREFIX}\"" "$dry_run"
                fi
            fi
        fi
    done

    echo ""
    if [ "$dry_run" = "true" ]; then
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${YELLOW}Para aplicar estos cambios, ejecuta:${NC}"
        echo -e "  ${GREEN}make setup${NC}  (o: $0 sin --dry-run)"
        echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    else
        echo -e "${GREEN}✓ Configuración completada${NC}"
        echo ""
        echo -e "${BLUE}Próximos pasos:${NC}"
        echo "  1. Revisa los cambios con: git diff"
        echo "  2. Verifica la configuración en los archivos modificados"
        echo "  3. Ejecuta: terraform init (en cada directorio)"
    fi

    echo ""
}

# Ejecutar función principal
main "$@"

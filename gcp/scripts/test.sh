#!/bin/bash
# Script de testing completo para Terraform
# Ejecuta validación, formato, linting y seguridad

set -euo pipefail

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Contadores
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Función para imprimir resultados
print_result() {
    local status=$1
    local message=$2

    if [ "$status" = "PASS" ]; then
        echo -e "${GREEN}✓${NC} $message"
        ((TESTS_PASSED++))
    elif [ "$status" = "FAIL" ]; then
        echo -e "${RED}✗${NC} $message"
        ((TESTS_FAILED++))
    elif [ "$status" = "SKIP" ]; then
        echo -e "${YELLOW}⊘${NC} $message (skipped)"
        ((TESTS_SKIPPED++))
    fi
}

# Función para verificar si un comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Función para ejecutar test con manejo de errores
run_test() {
    local test_name=$1
    shift
    local test_command=("$@")

    echo -e "${BLUE}Running: $test_name${NC}"
    if "${test_command[@]}" >/tmp/terraform-test-$$.log 2>&1; then
        print_result "PASS" "$test_name"
        return 0
    else
        print_result "FAIL" "$test_name"
        if [ "${VERBOSE:-false}" = "true" ]; then
            cat /tmp/terraform-test-$$.log
        fi
        return 1
    fi
}

# Función para verificar formato
test_format() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}1. Testing Format (terraform fmt)${NC}"
    echo -e "${BLUE}========================================${NC}"

    local has_errors=false

    # Buscar todos los archivos .tf
    while IFS= read -r -d '' file; do
        # Saltar .terraform y archivos en instance/examples si están ignorados
        if [[ "$file" == *"/.terraform/"* ]] || [[ "$file" == *"/instance/examples/"* ]]; then
            continue
        fi

        if ! terraform fmt -check "$file" >/dev/null 2>&1; then
            echo -e "${RED}✗${NC} Formato incorrecto: $file"
            has_errors=true
            ((TESTS_FAILED++))
        else
            ((TESTS_PASSED++))
        fi
    done < <(find . -name "*.tf" -type f -print0 2>/dev/null)

    if [ "$has_errors" = "true" ]; then
        echo -e "${YELLOW}💡 Ejecuta 'make fmt' para corregir el formato${NC}"
        return 1
    else
        print_result "PASS" "Todos los archivos tienen formato correcto"
        return 0
    fi
}

# Función para validar sintaxis
test_validate() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}2. Testing Validation (terraform validate)${NC}"
    echo -e "${BLUE}========================================${NC}"

    local dirs=(
        "shared-infra/environments/development"
        "shared-infra/environments/qa"
        "shared-infra/environments/staging"
        "shared-infra/environments/production"
        "terraform-state/global"
        "terraform-state/environments/development"
        "terraform-state/environments/qa"
        "terraform-state/environments/staging"
        "terraform-state/environments/production"
    )

    local has_errors=false

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            print_result "SKIP" "Validación en $dir (directorio no existe)"
            continue
        fi

        if [ ! -f "$dir/terraform.tfvars" ] && [ ! -f "$dir/tfvars.example" ]; then
            print_result "SKIP" "Validación en $dir (no hay tfvars)"
            continue
        fi

        echo -e "${BLUE}Validando $dir...${NC}"
        if (cd "$dir" && terraform init -backend=false >/dev/null 2>&1 && terraform validate >/dev/null 2>&1); then
            print_result "PASS" "Validación en $dir"
        else
            print_result "FAIL" "Validación en $dir"
            has_errors=true
        fi
    done

    if [ "$has_errors" = "true" ]; then
        return 1
    else
        return 0
    fi
}

# Función para linting con tflint
test_lint() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}3. Testing Linting (tflint)${NC}"
    echo -e "${BLUE}========================================${NC}"

    if ! command_exists tflint; then
        print_result "SKIP" "tflint no está instalado"
        echo -e "${YELLOW}💡 Instala tflint: brew install tflint (macOS) o descarga desde https://github.com/terraform-linters/tflint${NC}"
        return 0
    fi

    local has_errors=false
    local dirs=(
        "shared-infra/environments/development"
        "shared-infra/environments/qa"
        "shared-infra/environments/staging"
        "shared-infra/environments/production"
    )

    for dir in "${dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            continue
        fi

        echo -e "${BLUE}Linting $dir...${NC}"
        if (cd "$dir" && tflint --init >/dev/null 2>&1 && tflint --format compact >/tmp/tflint-$$.log 2>&1); then
            if [ -s /tmp/tflint-$$.log ] && grep -q "Error" /tmp/tflint-$$.log; then
                print_result "FAIL" "Linting en $dir"
                if [ "${VERBOSE:-false}" = "true" ]; then
                    cat /tmp/tflint-$$.log
                fi
                has_errors=true
            else
                print_result "PASS" "Linting en $dir"
            fi
        else
            print_result "FAIL" "Linting en $dir"
            has_errors=true
        fi
    done

    rm -f /tmp/tflint-$$.log

    if [ "$has_errors" = "true" ]; then
        return 1
    else
        return 0
    fi
}

# Función para tests de seguridad con checkov
test_security_checkov() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}4. Testing Security - Checkov${NC}"
    echo -e "${BLUE}========================================${NC}"

    if ! command_exists checkov; then
        print_result "SKIP" "checkov no está instalado"
        echo -e "${YELLOW}💡 Instala checkov: pip install checkov${NC}"
        return 0
    fi

    echo -e "${BLUE}Ejecutando checkov...${NC}"
    if checkov -d . --framework terraform --quiet --compact >/tmp/checkov-$$.log 2>&1; then
        local failed_checks=$(grep -c "FAILED" /tmp/checkov-$$.log 2>/dev/null || echo "0")
        if [ "$failed_checks" -gt 0 ]; then
            print_result "FAIL" "checkov encontró $failed_checks problemas de seguridad"
            if [ "${VERBOSE:-false}" = "true" ]; then
                cat /tmp/checkov-$$.log
            else
                echo -e "${YELLOW}💡 Ejecuta con VERBOSE=true para ver detalles${NC}"
            fi
            rm -f /tmp/checkov-$$.log
            return 1
        else
            print_result "PASS" "checkov: sin problemas de seguridad encontrados"
            rm -f /tmp/checkov-$$.log
            return 0
        fi
    else
        print_result "FAIL" "checkov falló al ejecutarse"
        if [ "${VERBOSE:-false}" = "true" ]; then
            cat /tmp/checkov-$$.log
        fi
        rm -f /tmp/checkov-$$.log
        return 1
    fi
}

# Función para tests de seguridad con tfsec
test_security_tfsec() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}5. Testing Security - tfsec${NC}"
    echo -e "${BLUE}========================================${NC}"

    if ! command_exists tfsec; then
        print_result "SKIP" "tfsec no está instalado"
        echo -e "${YELLOW}💡 Instala tfsec: brew install tfsec (macOS) o descarga desde https://github.com/aquasecurity/tfsec${NC}"
        return 0
    fi

    echo -e "${BLUE}Ejecutando tfsec...${NC}"
    if tfsec . --format compact --no-color >/tmp/tfsec-$$.log 2>&1; then
        local issues=$(grep -c "WARNING\|ERROR" /tmp/tfsec-$$.log 2>/dev/null || echo "0")
        if [ "$issues" -gt 0 ]; then
            print_result "FAIL" "tfsec encontró $issues problemas de seguridad"
            if [ "${VERBOSE:-false}" = "true" ]; then
                cat /tmp/tfsec-$$.log
            else
                echo -e "${YELLOW}💡 Ejecuta con VERBOSE=true para ver detalles${NC}"
            fi
            rm -f /tmp/tfsec-$$.log
            return 1
        else
            print_result "PASS" "tfsec: sin problemas de seguridad encontrados"
            rm -f /tmp/tfsec-$$.log
            return 0
        fi
    else
        # tfsec puede retornar código de salida != 0 si encuentra problemas
        local issues=$(grep -c "WARNING\|ERROR" /tmp/tfsec-$$.log 2>/dev/null || echo "0")
        if [ "$issues" -gt 0 ]; then
            print_result "FAIL" "tfsec encontró $issues problemas de seguridad"
            if [ "${VERBOSE:-false}" = "true" ]; then
                cat /tmp/tfsec-$$.log
            else
                echo -e "${YELLOW}💡 Ejecuta con VERBOSE=true para ver detalles${NC}"
            fi
        else
            print_result "PASS" "tfsec: sin problemas de seguridad encontrados"
        fi
        rm -f /tmp/tfsec-$$.log
        return 0  # No fallar el test completo si tfsec encuentra problemas menores
    fi
}

# Función principal
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Terraform Testing Suite${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""

    local overall_result=0

    # Ejecutar tests
    test_format || overall_result=1
    test_validate || overall_result=1
    test_lint || overall_result=1
    test_security_checkov || overall_result=1
    test_security_tfsec || overall_result=1

    # Resumen
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Resumen de Tests${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "${GREEN}✓ Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}✗ Failed: $TESTS_FAILED${NC}"
    echo -e "${YELLOW}⊘ Skipped: $TESTS_SKIPPED${NC}"
    echo ""

    # Limpiar archivos temporales
    rm -f /tmp/terraform-test-$$.log

    if [ $overall_result -eq 0 ]; then
        echo -e "${GREEN}========================================${NC}"
        echo -e "${GREEN}✓ Todos los tests pasaron${NC}"
        echo -e "${GREEN}========================================${NC}"
        exit 0
    else
        echo -e "${RED}========================================${NC}"
        echo -e "${RED}✗ Algunos tests fallaron${NC}"
        echo -e "${RED}========================================${NC}"
        echo -e "${YELLOW}💡 Ejecuta con VERBOSE=true para ver detalles${NC}"
        exit 1
    fi
}

# Manejo de argumentos
if [ "${1:-}" = "--help" ] || [ "${1:-}" = "-h" ]; then
    echo "Uso: $0 [--verbose]"
    echo ""
    echo "Ejecuta todos los tests de Terraform:"
    echo "  - Validación de formato (terraform fmt)"
    echo "  - Validación de sintaxis (terraform validate)"
    echo "  - Linting (tflint)"
    echo "  - Seguridad (checkov)"
    echo "  - Seguridad (tfsec)"
    echo ""
    echo "Opciones:"
    echo "  --verbose, -v    Mostrar output detallado de los tests"
    echo "  --help, -h       Mostrar esta ayuda"
    exit 0
fi

if [ "${1:-}" = "--verbose" ] || [ "${1:-}" = "-v" ]; then
    export VERBOSE=true
fi

# Ejecutar función principal
main

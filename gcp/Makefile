.PHONY: help check-versions fmt fmt-check validate clean init lint \
      setup setup-dry-run setup-verbose \
      plan apply \
      deploy-dev deploy-qa deploy-stg deploy-prod \
      output-dev output-qa output-stg output-prod \
      recover-global apply-state-environments \
      test test-verbose test-format test-validate test-lint test-security

# Variables
SCRIPT_DIR := scripts
TERRAFORM_DIRS := shared-infra/environments/development \
                  shared-infra/environments/qa \
                  shared-infra/environments/staging \
                  shared-infra/environments/production \
                  terraform-state/environments/development \
                  terraform-state/environments/qa \
                  terraform-state/environments/production \
                  terraform-state/environments/staging \
                  terraform-state/global

help: ## Mostrar esta ayuda
	@echo "Comandos disponibles:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; \
		{printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2}'

# ============================================================================
# Configuración y Setup
# ============================================================================

setup: ## Configurar proyecto para nuevo workspace/proyecto (requiere .env)
	@echo "Configurando proyecto..."
	@$(SCRIPT_DIR)/setup-project.sh

setup-dry-run: ## Mostrar cambios sin aplicarlos (requiere .env)
	@$(SCRIPT_DIR)/setup-project.sh --dry-run

setup-verbose: ## Configurar proyecto con información detallada
	@echo "Configurando proyecto (modo verbose)..."
	@$(SCRIPT_DIR)/setup-project.sh --verbose

# ============================================================================
# Validación y Formato
# ============================================================================

fmt: ## Formatear código Terraform
	@echo "Formateando código Terraform..."
	@terraform fmt -recursive .

fmt-check: ## Verificar formato sin modificar archivos
	@echo "Verificando formato de código Terraform..."
	@terraform fmt -check -recursive . || \
		(echo "Error: Algunos archivos necesitan formateo. " \
		"Ejecuta 'make fmt' para corregirlos." && exit 1)

validate: ## Validar sintaxis de Terraform (requiere terraform init y setup)
	@echo "Validando sintaxis de Terraform..."
	@echo "Verificando configuración..."
	@if [ ! -f .env ]; then \
		echo "  ⚠️  Archivo .env no encontrado. Ejecuta 'make setup' primero."; \
	fi
	@for dir in $(TERRAFORM_DIRS); do \
		if [ -d "$$dir" ]; then \
			echo "Validando $$dir..."; \
			if [ ! -f "$$dir/terraform.tfvars" ]; then \
				echo "  ⚠️  terraform.tfvars no existe. Crea el archivo basándote en tfvars.example"; \
				echo "      y ejecuta 'make setup' para configurarlo."; \
			else \
				(cd $$dir && terraform init -backend=false > /dev/null 2>&1 && \
					terraform validate) || \
					echo "  ⚠️  Skipped (requiere configuración)"; \
			fi \
		fi \
	done

lint: fmt-check validate ## Ejecutar todas las verificaciones de linting
	@echo "✓ Linting completado"

# ============================================================================
# Testing
# ============================================================================

test: ## Ejecutar todos los tests (formato, validación, linting, seguridad)
	@echo "Ejecutando suite completa de tests..."
	@$(SCRIPT_DIR)/test.sh

test-verbose: ## Ejecutar tests con output detallado
	@echo "Ejecutando suite completa de tests (verbose)..."
	@$(SCRIPT_DIR)/test.sh --verbose

test-format: ## Ejecutar solo test de formato
	@echo "Verificando formato..."
	@terraform fmt -check -recursive . || \
		(echo "Error: Algunos archivos necesitan formateo. Ejecuta 'make fmt' para corregirlos." && exit 1)

test-validate: validate ## Ejecutar solo test de validación (alias de validate)

test-lint: ## Ejecutar solo test de linting (requiere tflint)
	@if ! command -v tflint >/dev/null 2>&1; then \
		echo "⚠️  tflint no está instalado. Instala con: brew install tflint"; \
		exit 1; \
	fi
	@echo "Ejecutando tflint..."
	@for dir in shared-infra/environments/* terraform-state/environments/* terraform-state/global; do \
		if [ -d "$$dir" ] && [ -f "$$dir/main.tf" ]; then \
			echo "Linting $$dir..."; \
			(cd "$$dir" && tflint --init >/dev/null 2>&1 && tflint --format compact) || exit 1; \
		fi; \
	done

test-security: ## Ejecutar solo tests de seguridad (requiere checkov o tfsec)
	@echo "Ejecutando tests de seguridad..."
	@if command -v checkov >/dev/null 2>&1; then \
		echo "Ejecutando checkov..."; \
		checkov -d . --framework terraform --quiet --compact || exit 1; \
	else \
		echo "⚠️  checkov no está instalado. Instala con: pip install checkov"; \
	fi
	@if command -v tfsec >/dev/null 2>&1; then \
		echo "Ejecutando tfsec..."; \
		tfsec . --format compact --no-color || true; \
	else \
		echo "⚠️  tfsec no está instalado. Instala con: brew install tfsec"; \
	fi

# ============================================================================
# Limpieza e Inicialización
# ============================================================================

clean: ## Limpiar archivos temporales de Terraform
	@echo "Limpiando archivos temporales..."
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -type f -name "*.tfstate" -delete 2>/dev/null || true
	@find . -type f -name "*.tfstate.backup" -delete 2>/dev/null || true
	@find . -type f -name "*.tfplan" -delete 2>/dev/null || true
	@find . -type f -name "plan.json" -delete 2>/dev/null || true
	@find . -type f -name "tfplan" -delete 2>/dev/null || true
	@echo "✓ Limpieza completada"

init: ## Inicializar Terraform en todos los directorios (requiere backend)
	@echo "Inicializando Terraform..."
	@for dir in $(TERRAFORM_DIRS); do \
		if [ -d "$$dir" ]; then \
			echo "Inicializando $$dir..."; \
			(cd $$dir && terraform init) || \
				echo "  ⚠️  Error en $$dir"; \
		fi \
	done

# ============================================================================
# Plan y Apply (Interactivos)
# ============================================================================

plan: ## Plan interactivo: selecciona un directorio de TERRAFORM_DIRS
	@$(SCRIPT_DIR)/select-terraform-dir.sh "terraform plan" "plan"

apply: ## Apply interactivo: selecciona un directorio de TERRAFORM_DIRS
	@$(SCRIPT_DIR)/select-terraform-dir.sh "terraform apply" "apply"

# ============================================================================
# Outputs
# ============================================================================

output-dev: ## Mostrar outputs de shared-infra/development
	@cd shared-infra/environments/development && terraform output

output-qa: ## Mostrar outputs de shared-infra/qa
	@cd shared-infra/environments/qa && terraform output

output-stg: ## Mostrar outputs de shared-infra/staging
	@cd shared-infra/environments/staging && terraform output

output-prod: ## Mostrar outputs de shared-infra/production
	@cd shared-infra/environments/production && terraform output

# ============================================================================
# Despliegue de Ambientes
# ============================================================================

deploy-dev: ## Desplegar ambiente development (state + shared-infra)
	@$(SCRIPT_DIR)/deploy-environment.sh dev

deploy-qa: ## Desplegar ambiente QA (state + shared-infra)
	@$(SCRIPT_DIR)/deploy-environment.sh qa

deploy-stg: ## Desplegar ambiente staging (state + shared-infra, pregunta por GKE)
	@$(SCRIPT_DIR)/deploy-environment.sh stg

deploy-prod: ## Desplegar ambiente production (state + shared-infra, pregunta por GKE)
	@$(SCRIPT_DIR)/deploy-environment.sh prod

# ============================================================================
# Utilidades
# ============================================================================

check-versions: ## Verificar versiones más recientes de Terraform y providers
	@echo "Verificando versiones más recientes..."
	@$(SCRIPT_DIR)/check-versions.sh || true

recover-global: ## Recuperar estado del módulo global desde GCP (requiere .env)
	@$(SCRIPT_DIR)/recover-global-state.sh

apply-state-environments: ## Aplicar terraform apply en todos los terraform-state/environments (verifica que global existe)
	@$(SCRIPT_DIR)/apply-state-environments.sh

.DEFAULT_GOAL := help

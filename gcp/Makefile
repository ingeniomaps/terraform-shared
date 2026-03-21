.PHONY: help check-versions fmt fmt-check validate clean init lint \
      setup setup-dry-run setup-verbose \
      plan apply \
      deploy-dev deploy-qa deploy-stg deploy-prod \
      output-dev output-qa output-stg output-prod \
      recover-global  \
      test test-verbose test-format test-validate test-lint test-security

# Variables
SCRIPT_DIR := scripts
TERRAFORM_DIRS := shared-infra/environments/dev \
                  shared-infra/environments/qa \
                  shared-infra/environments/stg \
                  shared-infra/environments/prod \
                  bootstrap/global

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

output-dev: ## Mostrar outputs de shared-infra/dev
	@cd shared-infra/environments/dev && terraform output

output-qa: ## Mostrar outputs de shared-infra/qa
	@cd shared-infra/environments/qa && terraform output

output-stg: ## Mostrar outputs de shared-infra/stg
	@cd shared-infra/environments/stg && terraform output

output-prod: ## Mostrar outputs de shared-infra/prod
	@cd shared-infra/environments/prod && terraform output

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

# ============================================================================
# Costos (Infracost)
# ============================================================================

COST_ENV ?= dev

cost: ## Costo de un ambiente desplegado (COST_ENV=dev|qa|stg|prod)
	@if ! command -v infracost >/dev/null 2>&1; then \
		echo "infracost no instalado. Instala: https://www.infracost.io/docs/"; exit 1; \
	fi
	@echo "Estimando costos de shared-infra/$(COST_ENV)..."
	@cd shared-infra/environments/$(COST_ENV) && \
		terraform plan -out=tfplan.binary > /dev/null 2>&1 && \
		terraform show -json tfplan.binary > plan.json 2>/dev/null && \
		infracost breakdown --path plan.json --format table && \
		rm -f tfplan.binary plan.json

cost-all: ## Costo total de TODA la infraestructura (todos los ambientes)
	@if ! command -v infracost >/dev/null 2>&1; then \
		echo "infracost no instalado. Instala: https://www.infracost.io/docs/"; exit 1; \
	fi
	@echo "Estimando costos de toda la infraestructura..."
	@echo ""
	@TOTAL_FILE=$$(mktemp); \
	for env in dev qa stg prod; do \
		DIR="shared-infra/environments/$$env"; \
		if [ -d "$$DIR" ] && [ -f "$$DIR/terraform.tfvars" ]; then \
			echo "=== $$env ===" ; \
			cd "$$DIR" && \
			terraform plan -out=tfplan.binary > /dev/null 2>&1 && \
			terraform show -json tfplan.binary > plan.json 2>/dev/null && \
			infracost breakdown --path plan.json --format json 2>/dev/null > cost.json && \
			MONTHLY=$$(cat cost.json | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('totalMonthlyCost','0'))" 2>/dev/null || echo "0") && \
			echo "  $$MONTHLY USD/mes" && \
			echo "$$MONTHLY" >> "$$TOTAL_FILE" && \
			rm -f tfplan.binary plan.json cost.json && \
			cd ../../.. ; \
		fi; \
	done; \
	echo "" && \
	echo "===================================" && \
	TOTAL=$$(python3 -c "lines=open('$$TOTAL_FILE').readlines(); print(f'{sum(float(l.strip()) for l in lines if l.strip()):.2f}')") && \
	echo "  TOTAL: $$TOTAL USD/mes" && \
	echo "===================================" && \
	rm -f "$$TOTAL_FILE"

cost-estimate: ## Estimación rápida sin terraform plan (usa directorio)
	@if ! command -v infracost >/dev/null 2>&1; then \
		echo "infracost no instalado. Instala: https://www.infracost.io/docs/"; exit 1; \
	fi
	@echo "Estimación rápida de costos (todos los ambientes)..."
	@echo ""
	@for env in dev qa stg prod; do \
		DIR="shared-infra/environments/$$env"; \
		if [ -d "$$DIR" ] && [ -f "$$DIR/terraform.tfvars" ]; then \
			echo "=== $$env ===" ; \
			infracost breakdown --path "$$DIR" --format table 2>&1 | tail -5; \
			echo ""; \
		fi; \
	done

.DEFAULT_GOAL := help

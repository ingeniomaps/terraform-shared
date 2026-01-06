.PHONY: help fmt fmt-check validate plan apply destroy output clean

# Colores para output
GREEN  := \033[0;32m
YELLOW := \033[0;33m
NC     := \033[0m # No Color

# Directorio actual (donde está el Makefile)
INSTANCE_DIR := $(shell pwd)

help: ## Mostrar esta ayuda
	@echo "$(GREEN)Comandos disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

fmt: ## Formatear código Terraform
	@echo "$(GREEN)Formateando código Terraform...$(NC)"
	@find . -name "*.tf" -type f -exec terraform fmt {} \;
	@echo "$(GREEN)✓ Formateo completado$(NC)"

fmt-check: ## Verificar formato sin modificar
	@echo "$(GREEN)Verificando formato...$(NC)"
	@terraform fmt -check -recursive
	@echo "$(GREEN)✓ Formato correcto$(NC)"

validate: ## Validar configuración Terraform (requiere terraform init)
	@echo "$(GREEN)Validando configuración...$(NC)"
	@if [ ! -d ".terraform" ]; then \
		echo "$(YELLOW)⚠ Ejecuta 'terraform init' primero$(NC)"; \
		exit 1; \
	fi
	@terraform validate
	@echo "$(GREEN)✓ Validación completada$(NC)"

plan: ## Ejecutar terraform plan (requiere estar en un ejemplo)
	@if [ ! -f "main.tf" ]; then \
		echo "$(YELLOW)⚠ Debes estar en un directorio de ejemplo (vm-docker, vm-artifact, gke)$(NC)"; \
		echo "$(YELLOW)Ejemplo: cd examples/vm-docker && make plan$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Ejecutando terraform plan...$(NC)"
	@terraform plan

apply: ## Ejecutar terraform apply (requiere estar en un ejemplo)
	@if [ ! -f "main.tf" ]; then \
		echo "$(YELLOW)⚠ Debes estar en un directorio de ejemplo$(NC)"; \
		echo "$(YELLOW)Ejemplo: cd examples/vm-docker && make apply$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Ejecutando terraform apply...$(NC)"
	@terraform apply

destroy: ## Ejecutar terraform destroy (requiere estar en un ejemplo)
	@if [ ! -f "main.tf" ]; then \
		echo "$(YELLOW)⚠ Debes estar en un directorio de ejemplo$(NC)"; \
		echo "$(YELLOW)Ejemplo: cd examples/vm-docker && make destroy$(NC)"; \
		exit 1; \
	fi
	@echo "$(YELLOW)⚠ ADVERTENCIA: Esto destruirá todos los recursos$(NC)"
	@read -p "¿Estás seguro? (yes/no): " confirm && [ "$$confirm" = "yes" ] || exit 1
	@echo "$(GREEN)Ejecutando terraform destroy...$(NC)"
	@terraform destroy

output: ## Mostrar outputs de Terraform (requiere estar en un ejemplo)
	@if [ ! -f "main.tf" ]; then \
		echo "$(YELLOW)⚠ Debes estar en un directorio de ejemplo$(NC)"; \
		echo "$(YELLOW)Ejemplo: cd examples/vm-docker && make output$(NC)"; \
		exit 1; \
	fi
	@terraform output

init: ## Inicializar Terraform (requiere estar en un ejemplo)
	@if [ ! -f "main.tf" ]; then \
		echo "$(YELLOW)⚠ Debes estar en un directorio de ejemplo$(NC)"; \
		echo "$(YELLOW)Ejemplo: cd examples/vm-docker && make init$(NC)"; \
		exit 1; \
	fi
	@echo "$(GREEN)Inicializando Terraform...$(NC)"
	@terraform init

clean: ## Limpiar archivos temporales de Terraform
	@echo "$(GREEN)Limpiando archivos temporales...$(NC)"
	@find . -type d -name ".terraform" -exec rm -rf {} + 2>/dev/null || true
	@find . -type f -name "*.tfstate" -delete 2>/dev/null || true
	@find . -type f -name "*.tfstate.backup" -delete 2>/dev/null || true
	@find . -type f -name ".terraform.lock.hcl" -delete 2>/dev/null || true
	@find . -type f -name "tfplan" -delete 2>/dev/null || true
	@echo "$(GREEN)✓ Limpieza completada$(NC)"

# Comandos específicos por ejemplo
vm-docker-init: ## Inicializar ejemplo vm-docker
	@cd examples/vm-docker && terraform init

vm-docker-plan: ## Plan para ejemplo vm-docker
	@cd examples/vm-docker && terraform plan

vm-docker-apply: ## Apply para ejemplo vm-docker
	@cd examples/vm-docker && terraform apply

vm-artifact-init: ## Inicializar ejemplo vm-artifact
	@cd examples/vm-artifact && terraform init

vm-artifact-plan: ## Plan para ejemplo vm-artifact
	@cd examples/vm-artifact && terraform plan

vm-artifact-apply: ## Apply para ejemplo vm-artifact
	@cd examples/vm-artifact && terraform apply

gke-init: ## Inicializar ejemplo gke
	@cd examples/gke && terraform init

gke-plan: ## Plan para ejemplo gke
	@cd examples/gke && terraform plan

gke-apply: ## Apply para ejemplo gke
	@cd examples/gke && terraform apply

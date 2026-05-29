# ==============================================================================
# Makefile - shared-infra global (org-policies + VPC Service Controls, singleton)
# ==============================================================================
# IDENTICO en dev/stg/prod/qa. Lo unico que cambia entre carpetas es
# terraform.tfvars. Se auto-carga (no -var-file); el backend prefix se deriva
# del nombre de la carpeta en `make init` (dev/ -> shared/dev).
# ==============================================================================

.PHONY: help init plan apply fmt validate outputs

help: ## Mostrar esta ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-12s\033[0m %s\n", $$1, $$2}'

init: ## Inicializar Terraform (backend del entorno; prefix = nombre de la carpeta)
	terraform init -backend-config="prefix=shared/$(notdir $(CURDIR))"

plan: ## Ver cambios sin aplicar
	terraform plan

apply: ## Aplicar cambios
	terraform apply

fmt: ## Formatear
	terraform fmt -recursive

validate: ## Validar
	terraform validate

outputs: ## Ver outputs
	terraform output

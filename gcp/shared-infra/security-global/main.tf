terraform {
  required_version = ">= 1.14.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.9.1"
    }
  }

  # Estado en GCS. El prefix lo pasa `make init` por -backend-config
  # (shared/security-global). State propio, separado de los entornos.
  backend "gcs" {
    bucket = "workspace-state"
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.credentials_file != null ? file("${path.root}/../../${var.credentials_file}") : null
}

data "google_project" "current" {
  project_id = var.project_id
}

locals {
  account_name  = "${var.workspace}-${var.env}-sa"
  is_production = var.env == "prod"
}

# ==============================================================================
# Org Policies + VPC Service Controls — PROJECT/ORG-singleton.
# ==============================================================================
# Se aplican UNA sola vez por proyecto (no por entorno): las org-policies son
# project-scoped (con project_id compartido, crearlas por-entorno = varios states
# peleando por el mismo recurso) y el perímetro VPC-SC protege el proyecto entero.
# Antes vivían dentro del módulo security per-env (god-module) — separados acá
# para aislar blast-radius: un cambio de IAM de un entorno ya no toca el perímetro.
module "security_policies" {
  source = "../modules/security/security"

  project_id                  = var.project_id
  organization_id             = var.organization_id
  allowed_domains             = var.allowed_domains
  enable_vpc_service_controls = var.enable_vpc_service_controls
  enable_org_policies         = var.enable_org_policies
  account_name                = local.account_name
  workspace                   = var.workspace
  env                         = var.env
  project_number              = data.google_project.current.number
  is_production               = local.is_production
}

# Guardrail: prod endurecido exige VPC-SC (gateado por enforce_prod_hardening).
check "production_requires_vpc_service_controls" {
  assert {
    condition     = !var.enforce_prod_hardening || var.env != "prod" || var.enable_vpc_service_controls == true
    error_message = "Prod endurecido debe tener enable_vpc_service_controls = true (o enforce_prod_hardening = false en transición)."
  }
}

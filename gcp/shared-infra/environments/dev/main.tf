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

  # Estado en GCS. El prefix lo pasa `make init` por -backend-config (deriva del
  # nombre de la carpeta: dev/ -> shared/dev, prod/ -> shared/prod).
  backend "gcs" {
    bucket = "workspace-state"
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.credentials_file != null ? file("${path.root}/../../../${var.credentials_file}") : null
}

# ==============================================================================
# Validaciones de seguridad
# ==============================================================================
# Los checks production_* se gatean con enforce_prod_hardening: en el prod
# transicional (mono, HTTP directo) va false y se relajan; cuando prod pase a
# LB se pone true y vuelven a exigirse. En dev/stg/qa son no-op (solo si env ==
# "prod"). El check de VPC-SC vive en shared-infra/security-global/.

check "http_access_exclusivity" {
  assert {
    condition     = !(var.enable_public_http && var.enable_restricted_http)
    error_message = "enable_public_http y enable_restricted_http no pueden ser true al mismo tiempo."
  }
}

check "production_no_public_http" {
  assert {
    condition     = !var.enforce_prod_hardening || var.env != "prod" || var.enable_public_http == false
    error_message = "Prod endurecido no debe tener enable_public_http = true (usar LB o enable_restricted_http; o enforce_prod_hardening = false en transicion)."
  }
}

check "production_requires_restricted_or_lb" {
  assert {
    condition     = !var.enforce_prod_hardening || var.env != "prod" || var.enable_restricted_http == true || var.enable_public_http == false
    error_message = "Prod endurecido debe tener enable_restricted_http = true o acceso via Load Balancer."
  }
}

module "security" {
  source = "../../modules/security"

  project_id = var.project_id
  workspace  = var.workspace
  env        = var.env

  registry_name     = var.registry_name
  registry_location = var.region

  enable_group_iam = var.enable_group_iam
  admin_groups     = var.admin_groups

  create_admin_sa           = false
  enable_dev_reader         = var.enable_dev_reader
  create_vm_start_stop_role = var.create_vm_start_stop_role
  create_audit_configs      = var.create_audit_configs

  alert_notification_channels = var.alert_notification_channels

  break_glass_max_session_duration = var.break_glass_max_session_duration
  log_bucket_suffix                = var.log_bucket_suffix
}

# ==============================================================================
# Artifact Registry — el repo lo CREA bootstrap/global (dueno unico, singleton
# global). Aca cada entorno solo bindea SUS service accounts como reader/writer
# del repo compartido. Requiere que bootstrap haya corrido antes.
# ==============================================================================
resource "google_artifact_registry_repository_iam_member" "ar_readers" {
  for_each = toset(compact([
    module.security.vm_reader_email,
    var.enable_dev_reader ? module.security.dev_reader_email : null,
  ]))

  project    = var.project_id
  location   = var.region
  repository = var.registry_name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${each.value}"
}

resource "google_artifact_registry_repository_iam_member" "ar_writers" {
  for_each = toset(compact([
    module.security.ci_cd_writer_email,
    var.enable_dev_reader ? module.security.dev_reader_email : null,
  ]))

  project    = var.project_id
  location   = var.region
  repository = var.registry_name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${each.value}"
}

module "network" {
  source = "../../modules/network"

  project_id = var.project_id
  workspace  = var.workspace
  region     = var.region
  env        = var.env

  # project-level
  enable_oslogin_metadata = var.enable_oslogin_metadata

  # subnet
  vm_subnet_cidr    = var.vm_subnet_cidr
  enable_gke        = var.enable_gke
  gke_subnet_cidr   = var.gke_subnet_cidr
  gke_pods_cidr     = var.gke_pods_cidr
  gke_services_cidr = var.gke_services_cidr

  # firewall
  vm_service_account_email = module.security.vm_reader_email
  enable_public_http       = var.enable_public_http
  enable_restricted_http   = var.enable_restricted_http
  corporate_ip_ranges      = var.corporate_ip_ranges
  gke_master_cidr          = var.gke_master_cidr

  # vpc_peering
  enable_vpc_peering = var.enable_vpc_peering
  peer_project_id    = var.peer_project_id
  peer_vpc_name      = var.peer_vpc_name
}

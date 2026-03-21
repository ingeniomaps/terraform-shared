terraform {
  required_version = ">= 1.14.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.credentials_file != null ? file("${path.root}/../../${var.credentials_file}") : null
}

module "terraform_state_bucket" {
  source                = "../modules/gcs_bucket"
  bucket_name           = var.bucket_name
  region                = var.region
  prevent_destroy       = true # Proteger bucket global
  retention_period_days = 90   # 90 días de retención para bucket global
  retention_locked      = true # Bloquear política para bucket global
}

# ==============================================================================
# Artifact Registry — repositorio Docker único para todos los ambientes
# ==============================================================================
# Se crea aquí (global) para que exista antes que cualquier ambiente.
# Todas las imágenes van al mismo repo, diferenciadas por tag:
#   {repo}/{service}:abc1234   (CI build)
#   {repo}/{service}:v1.2.0    (release)

resource "google_artifact_registry_repository" "docker" {
  count = var.registry_name != null ? 1 : 0

  location      = var.region
  repository_id = var.registry_name
  format        = "DOCKER"
  description   = "Docker images for all environments"

  docker_config {
    immutable_tags = false # Permitir re-tag (latest se actualiza)
  }

  labels = {
    managed_by = "terraform"
    scope      = "global"
  }
}
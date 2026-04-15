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

# ==============================================================================
# Recursos project-level — singleton compartidos entre todos los ambientes
# ==============================================================================
# Estos recursos son de proyecto, no de ambiente. Se gestionan aquí para que
# ningún ambiente pueda crearlos o destruirlos accidentalmente.

# OS Login — habilita autenticación centralizada para SSH en todas las VMs
resource "google_compute_project_metadata" "enable_oslogin" {
  project = var.project_id
  metadata = {
    enable-oslogin = "TRUE"
  }
}

# Custom role: permisos mínimos para encender/apagar VMs (Cloud Scheduler)
resource "google_project_iam_custom_role" "vm_start_stop" {
  project     = var.project_id
  role_id     = "vmStartStop"
  title       = "VM Start/Stop"
  description = "Permite encender y apagar instancias de Compute Engine (usado por Cloud Scheduler)"
  permissions = [
    "compute.instances.start",
    "compute.instances.stop",
  ]
}

# ==============================================================================
# Audit Logging — configura qué operaciones se registran por servicio GCP
# ==============================================================================

resource "google_project_iam_audit_config" "network_audit" {
  project = var.project_id
  service = "compute.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

resource "google_project_iam_audit_config" "iam_audit" {
  project = var.project_id
  service = "iam.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

resource "google_project_iam_audit_config" "container_audit" {
  project = var.project_id
  service = "container.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

resource "google_project_iam_audit_config" "artifact_registry_audit" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

resource "google_project_iam_audit_config" "storage_audit" {
  project = var.project_id
  service = "storage.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}
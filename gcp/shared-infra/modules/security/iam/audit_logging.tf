# ============================================================================
# AUDIT LOGGING CONFIGURATION
#
# Configura qué tipos de operaciones se registran para cada servicio de GCP
# Esto permite auditar cambios y accesos en el proyecto.
# ============================================================================

# Network Audit: registra todas las acciones sobre recursos de Compute Engine
resource "google_project_iam_audit_config" "network_audit" {
  project = var.project_id
  service = "compute.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

# IAM Audit: registra cambios en políticas IAM y accesos administrativos
resource "google_project_iam_audit_config" "iam_audit" {
  project = var.project_id
  service = "iam.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

# Container Audit: registra acciones en Google Kubernetes Engine (GKE)
resource "google_project_iam_audit_config" "container_audit" {
  project = var.project_id
  service = "container.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

# Artifact Registry Audit: registra acciones en repositorios de artefactos
resource "google_project_iam_audit_config" "artifact_registry_audit" {
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

# Storage Audit: registra accesos y cambios en Google Cloud Storage
resource "google_project_iam_audit_config" "storage_audit" {
  project = var.project_id
  service = "storage.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

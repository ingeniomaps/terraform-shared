# ============================================================================
# AUDIT LOGGING CONFIGURATION
#
# Configura qué tipos de operaciones se registran para cada servicio de GCP.
# Gestionado por bootstrap/global. Solo crear si create_audit_configs = true
# (para retrocompatibilidad con ambientes que aún no migraron a bootstrap).
# ============================================================================

# Migración: audit configs pasaron de sin count a count
moved {
  from = google_project_iam_audit_config.network_audit
  to   = google_project_iam_audit_config.network_audit[0]
}
moved {
  from = google_project_iam_audit_config.iam_audit
  to   = google_project_iam_audit_config.iam_audit[0]
}
moved {
  from = google_project_iam_audit_config.container_audit
  to   = google_project_iam_audit_config.container_audit[0]
}
moved {
  from = google_project_iam_audit_config.artifact_registry_audit
  to   = google_project_iam_audit_config.artifact_registry_audit[0]
}
moved {
  from = google_project_iam_audit_config.storage_audit
  to   = google_project_iam_audit_config.storage_audit[0]
}

resource "google_project_iam_audit_config" "network_audit" {
  count   = var.create_audit_configs ? 1 : 0
  project = var.project_id
  service = "compute.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

resource "google_project_iam_audit_config" "iam_audit" {
  count   = var.create_audit_configs ? 1 : 0
  project = var.project_id
  service = "iam.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

resource "google_project_iam_audit_config" "container_audit" {
  count   = var.create_audit_configs ? 1 : 0
  project = var.project_id
  service = "container.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

resource "google_project_iam_audit_config" "artifact_registry_audit" {
  count   = var.create_audit_configs ? 1 : 0
  project = var.project_id
  service = "artifactregistry.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

resource "google_project_iam_audit_config" "storage_audit" {
  count   = var.create_audit_configs ? 1 : 0
  project = var.project_id
  service = "storage.googleapis.com"

  audit_log_config { log_type = "ADMIN_READ" }
  audit_log_config { log_type = "DATA_WRITE" }
}

# ============================================================================
# IAM – SERVICE ACCOUNTS (LOGGING & MONITORING)
#
# Permisos mínimos necesarios para que las cuentas de servicio puedan
# emitir logs y métricas a Cloud Logging y Cloud Monitoring.
# ============================================================================

# Permite que el pipeline de CI/CD escriba logs en Cloud Logging.
resource "google_project_iam_member" "ci_cd_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${var.ci_cd_writer_email}"
}

# Permite que el pipeline de CI/CD acceda a VMs vía IAP para deployments
resource "google_project_iam_member" "ci_cd_iap_access" {
  project = var.project_id
  role    = "roles/iap.tunnelResourceAccessor"
  member  = "serviceAccount:${var.ci_cd_writer_email}"
}

# Permite que el pipeline de CI/CD lea información de instancias (necesario para gcloud compute ssh)
resource "google_project_iam_member" "ci_cd_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${var.ci_cd_writer_email}"
}

# Permite que las VMs o workloads asociados publiquen métricas personalizadas
resource "google_project_iam_member" "vm_metric_writer" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${var.vm_reader_email}"
}

# Permite que las VMs o workloads escriban logs de aplicación y sistema
resource "google_project_iam_member" "vm_log_writer" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${var.vm_reader_email}"
}

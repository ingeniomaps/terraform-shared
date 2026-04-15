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

# Permite que el pipeline de CI/CD use OS Login para SSH a VMs
resource "google_project_iam_member" "ci_cd_os_login" {
  project = var.project_id
  role    = "roles/compute.osLogin"
  member  = "serviceAccount:${var.ci_cd_writer_email}"
}

# Permite que el pipeline de CI/CD haga SSH a VMs usando OS Login
resource "google_project_iam_member" "ci_cd_os_admin_login" {
  project = var.project_id
  role    = "roles/compute.osAdminLogin"
  member  = "serviceAccount:${var.ci_cd_writer_email}"
}

# Permite que el pipeline de CI/CD use instancias de Compute Engine
# (incluye compute.instances.use necesario para SSH)
resource "google_project_iam_member" "ci_cd_instance_user" {
  project = var.project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${var.ci_cd_writer_email}"
}

# Permite que el pipeline de CI/CD actúe como service accounts
# (necesario cuando la VM tiene una service account adjunta)
resource "google_project_iam_member" "ci_cd_service_account_user" {
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
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

# Permite que las VMs hagan pull de imágenes desde Artifact Registry
resource "google_project_iam_member" "vm_artifact_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${var.vm_reader_email}"
}

# Migración: el custom role pasó de sin count a count (retrocompatibilidad)
moved {
  from = google_project_iam_custom_role.vm_start_stop
  to   = google_project_iam_custom_role.vm_start_stop[0]
}

# Custom role con permisos mínimos para encender/apagar VMs
# Usado por Cloud Scheduler para gestión automática de ciclo de vida de VMs
# Compartido entre ambientes — se crea solo si var.create_vm_start_stop_role = true
# El primer ambiente que lo despliega (generalmente dev) lo crea.
# Los demás ambientes lo referencian con create_vm_start_stop_role = false.
resource "google_project_iam_custom_role" "vm_start_stop" {
  count       = var.create_vm_start_stop_role ? 1 : 0
  project     = var.project_id
  role_id     = "vmStartStop"
  title       = "VM Start/Stop"
  description = "Permite encender y apagar instancias de Compute Engine (usado por Cloud Scheduler)"
  permissions = [
    "compute.instances.start",
    "compute.instances.stop",
  ]
}

# Asigna el custom role a la SA de VMs para que Cloud Scheduler pueda operar
resource "google_project_iam_member" "vm_start_stop" {
  project = var.project_id
  role    = "projects/${var.project_id}/roles/vmStartStop"
  member  = "serviceAccount:${var.vm_reader_email}"
}

# Permite que el pipeline CI/CD haga push de imágenes a Artifact Registry
resource "google_project_iam_member" "ci_cd_artifact_writer" {
  project = var.project_id
  role    = "roles/artifactregistry.writer"
  member  = "serviceAccount:${var.ci_cd_writer_email}"
}

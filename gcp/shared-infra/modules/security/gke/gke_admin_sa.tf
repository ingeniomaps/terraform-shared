# ============================================================================
# GKE ADMIN SERVICE ACCOUNT - Administración del cluster
# ============================================================================

# Creación de la Service Account para administración del cluster GKE
resource "google_service_account" "gke_admin_sa" {
  count        = var.create_admin_sa ? 1 : 0
  account_id   = "${var.account_name}-gke-admin-sa"
  display_name = "GKE Cluster Admin SA"
  description  = "Service Account para gestión de GKE y red"
}

# Asignación del rol de administrador de contenedores al GKE Admin SA
resource "google_project_iam_member" "gke_admin_container_admin" {
  count   = var.create_admin_sa ? 1 : 0
  project = var.project_id
  role    = "roles/container.admin"
  member  = "serviceAccount:${google_service_account.gke_admin_sa[0].email}"
}

# Asignación del rol de administrador de red al GKE Admin SA
resource "google_project_iam_member" "gke_admin_network_admin" {
  count   = var.create_admin_sa ? 1 : 0
  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.gke_admin_sa[0].email}"
}

# Permitir que la Service Account sea usada por otros recursos de IAM
resource "google_project_iam_member" "gke_admin_sa_user" {
  count   = var.create_admin_sa ? 1 : 0
  project = var.project_id
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.gke_admin_sa[0].email}"
}
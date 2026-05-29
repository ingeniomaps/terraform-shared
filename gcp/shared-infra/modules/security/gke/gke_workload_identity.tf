# ============================================================================
# GKE WORKLOAD IDENTITY - Para pods en GKE
# ============================================================================

# Creación de la Service Account para workloads que se ejecutan en GKE
resource "google_service_account" "gke_workload" {
  count        = var.create_admin_sa ? 1 : 0
  account_id   = "${var.account_name}-gke-workload"
  display_name = "GKE Workload Identity SA"
  description  = "Service Account para workloads en GKE"
}

# Vinculación de la Service Account de Workload con Workload Identity
resource "google_service_account_iam_member" "workload_identity_binding" {
  count              = var.create_admin_sa ? 1 : 0
  service_account_id = google_service_account.gke_workload[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.gke_workload_namespace}/${var.gke_workload_ksa}]"
}

# Permiso para que la Service Account lea del Artifact Registry
resource "google_artifact_registry_repository_iam_member" "gke_workload_reader" {
  count      = var.create_admin_sa ? 1 : 0
  project    = var.project_id
  location   = var.registry_location
  repository = var.registry_name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${google_service_account.gke_workload[0].email}"
}
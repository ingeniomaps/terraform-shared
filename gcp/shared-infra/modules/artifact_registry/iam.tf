


# ============================================================================
# IAM - Permisos para LECTORES
# (VMs, GKE nodes, workloads que consumen imágenes)
# ============================================================================
resource "google_artifact_registry_repository_iam_member" "readers" {
  for_each = toset(var.readers)

  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${each.value}"

  depends_on = [google_artifact_registry_repository.docker]
}

# ============================================================================
# IAM - Permisos para ESCRITORES
# (CI/CD, pipelines que publican imágenes)
# ============================================================================
resource "google_artifact_registry_repository_iam_member" "writers" {
  for_each = toset(var.writers)

  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${each.value}"

  depends_on = [google_artifact_registry_repository.docker]
}

# ============================================================================
# IAM - Permisos para ADMINISTRADORES (opcional)
# (Personas o equipos que gestionan el registry)
# ============================================================================
resource "google_artifact_registry_repository_iam_member" "admins" {
  for_each = toset(var.admins)

  location   = google_artifact_registry_repository.docker.location
  repository = google_artifact_registry_repository.docker.name
  role       = "roles/artifactregistry.repoAdmin"
  member     = "serviceAccount:${each.value}"

  depends_on = [google_artifact_registry_repository.docker]
}
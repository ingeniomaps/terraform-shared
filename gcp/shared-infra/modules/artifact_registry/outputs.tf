output "repository_name" {
  description = "Nombre completo del repositorio (resource name)"
  value       = google_artifact_registry_repository.docker.name
}

output "repository_url" {
  description = "URL completa del repositorio para Docker pull/push"
  value       = "${google_artifact_registry_repository.docker.location}-docker.pkg.dev/${google_artifact_registry_repository.docker.project}/${google_artifact_registry_repository.docker.repository_id}"
}
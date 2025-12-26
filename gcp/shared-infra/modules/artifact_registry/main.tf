# ============================================================================
# Artifact Registry - Repositorio Docker
# ============================================================================
resource "google_artifact_registry_repository" "docker" {
  provider      = google
  location      = var.region
  repository_id = var.repository_id
  format        = "DOCKER"
  description   = var.description

  labels = var.labels

  docker_config {
    immutable_tags = true
  }

  lifecycle {
    prevent_destroy = false
  }

  # Permite definir políticas de limpieza automática de imágenes
  dynamic "cleanup_policies" {
    for_each = var.enable_cleanup_policies ? var.cleanup_policies : []
    content {
      id     = cleanup_policies.value.id
      action = cleanup_policies.value.action

      dynamic "condition" {
        for_each = cleanup_policies.value.condition != null ? [cleanup_policies.value.condition] : []
        content {
          tag_state             = lookup(condition.value, "tag_state", null)
          tag_prefixes          = lookup(condition.value, "tag_prefixes", null)
          older_than            = lookup(condition.value, "older_than", null)
          newer_than            = lookup(condition.value, "newer_than", null)
          package_name_prefixes = lookup(condition.value, "package_name_prefixes", null)
        }
      }

      dynamic "most_recent_versions" {
        for_each = cleanup_policies.value.most_recent_versions != null ? [cleanup_policies.value.most_recent_versions] : []
        content {
          package_name_prefixes = most_recent_versions.value.package_name_prefixes
          keep_count            = most_recent_versions.value.keep_count
        }
      }
    }
  }
}
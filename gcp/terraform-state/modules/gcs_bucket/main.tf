# -------------------------------------------------------------------------
# Cloud Storage Bucket
# -------------------------------------------------------------------------
resource "google_storage_bucket" "bucket" {
  name                        = var.bucket_name
  location                    = var.region
  storage_class               = "STANDARD"
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  # Lifecycle para versiones antiguas (no el estado actual)
  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      days_since_noncurrent_time = 365
      num_newer_versions         = 10
    }
  }

  # Opcional: proteger buckets de prod
  lifecycle {
    prevent_destroy = true
  }

  # Retention policy (objeto bloqueado por X días)
  retention_policy {
    retention_period = 2592000  # 30 días en segundos (30 * 24 * 60 * 60)
    is_locked        = true  # false en staging, true en prod
  }
}

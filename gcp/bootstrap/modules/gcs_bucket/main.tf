# -------------------------------------------------------------------------
# Cloud Storage Bucket
# -------------------------------------------------------------------------
# NOTA: Terraform no permite variables directamente en lifecycle blocks
# Solución: Usamos count para crear dos recursos condicionales
# - bucket_protected: cuando prevent_destroy = true
# - bucket_unprotected: cuando prevent_destroy = false
# Solo uno de los dos se creará según el valor de var.prevent_destroy

resource "google_storage_bucket" "bucket_protected" {
  count                       = var.prevent_destroy ? 1 : 0
  name                        = var.bucket_name
  location                    = var.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      days_since_noncurrent_time = var.lifecycle_days_since_noncurrent
      num_newer_versions         = var.lifecycle_num_newer_versions
    }
  }

  lifecycle {
    prevent_destroy = true
  }

  dynamic "retention_policy" {
    for_each = var.retention_period_days > 0 ? [1] : []
    content {
      retention_period = var.retention_period_days * 24 * 60 * 60
      is_locked        = var.retention_locked
    }
  }
}

resource "google_storage_bucket" "bucket_unprotected" {
  count                       = var.prevent_destroy ? 0 : 1
  name                        = var.bucket_name
  location                    = var.region
  storage_class               = var.storage_class
  uniform_bucket_level_access = true

  versioning {
    enabled = true
  }

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      days_since_noncurrent_time = var.lifecycle_days_since_noncurrent
      num_newer_versions         = var.lifecycle_num_newer_versions
    }
  }

  lifecycle {
    prevent_destroy = false
  }

  dynamic "retention_policy" {
    for_each = var.retention_period_days > 0 ? [1] : []
    content {
      retention_period = var.retention_period_days * 24 * 60 * 60
      is_locked        = var.retention_locked
    }
  }
}

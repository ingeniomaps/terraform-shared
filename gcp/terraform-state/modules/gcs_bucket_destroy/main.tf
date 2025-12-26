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

  # Opcional: proteger buckets de prod
  lifecycle {
    prevent_destroy = false
  }
}

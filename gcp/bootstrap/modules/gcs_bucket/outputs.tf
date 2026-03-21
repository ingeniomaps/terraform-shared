output "bucket_name" {
  description = "Nombre del bucket de Terraform para este entorno"
  value = var.prevent_destroy ? (
    google_storage_bucket.bucket_protected[0].name
    ) : (
    google_storage_bucket.bucket_unprotected[0].name
  )
}

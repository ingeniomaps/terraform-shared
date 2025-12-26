output "bucket_name" {
  description = "Nombre del bucket de Terraform para este entorno"
  value       = google_storage_bucket.bucket.name
}

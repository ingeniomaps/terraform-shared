# IDs de los buckets de logs creados
output "log_buckets" {
  description = "IDs de los buckets de logs creados"
  value = {
    iam_audit    = google_logging_project_bucket_config.iam_audit_logs.bucket_id
    security     = google_logging_project_bucket_config.security_alerts.bucket_id
    network_logs = google_logging_project_bucket_config.network_logs.bucket_id
  }
}
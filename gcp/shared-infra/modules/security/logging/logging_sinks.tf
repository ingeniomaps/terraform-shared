# ============================================================================
# LOGGING SINKS
#
# Los sinks redirigen logs específicos a buckets de Logging configurados previamente.
# Se usan filtros para capturar eventos críticos como cambios de IAM, uso de cuentas
# Break Glass, cambios de red o modificaciones en Artifact Registry.
# ============================================================================

# Sink para capturar cambios en IAM y políticas de Compute
resource "google_logging_project_sink" "iam_changes_sink" {
  name                   = "iam-changes-sink-${var.registry_name}-${var.env}"
  destination            = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/${google_logging_project_bucket_config.iam_audit_logs.bucket_id}"
  filter                 = <<-EOT
    protoPayload.serviceName="iam.googleapis.com"
    OR (protoPayload.serviceName="compute.googleapis.com"
        AND protoPayload.methodName=~".*setIamPolicy.*")
  EOT
  unique_writer_identity = true
}

# Sink para registrar el uso de la cuenta Break Glass
resource "google_logging_project_sink" "break_glass_usage" {
  name                   = "break-glass-usage-${var.registry_name}-${var.env}"
  destination            = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/${google_logging_project_bucket_config.security_alerts.bucket_id}"
  filter                 = "protoPayload.authenticationInfo.principalEmail=\"${var.break_glass_email}\""
  unique_writer_identity = true
}

# Sink para capturar cambios de red (firewalls, rutas, redes)
resource "google_logging_project_sink" "network_changes_sink" {
  name                   = "network-changes-sink-${var.registry_name}-${var.env}"
  destination            = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/${google_logging_project_bucket_config.network_logs.bucket_id}"
  filter                 = <<-EOT
    protoPayload.serviceName="compute.googleapis.com"
    AND (protoPayload.methodName=~".*firewall.*"
         OR protoPayload.methodName=~".*route.*"
         OR protoPayload.methodName=~".*network.*")
  EOT
  unique_writer_identity = true
}

# Sink para capturar cambios críticos en Artifact Registry
resource "google_logging_project_sink" "artifact_registry_changes" {
  name                   = "artifact-registry-changes-${var.registry_name}-${var.env}"
  destination            = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/${google_logging_project_bucket_config.security_alerts.bucket_id}"
  filter                 = <<-EOT
    protoPayload.serviceName="artifactregistry.googleapis.com"
    AND (protoPayload.methodName=~".*Delete.*"
         OR protoPayload.methodName=~".*setIamPolicy.*")
  EOT
  unique_writer_identity = true
}

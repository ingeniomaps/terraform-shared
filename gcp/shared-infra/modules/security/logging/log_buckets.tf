# ============================================================================
# LOG BUCKETS: Configuración de buckets para retención de logs
#
# Estos buckets se usan para almacenar logs de auditoría y monitoreo.
# Se definen con retención específica según el ambiente (producción o no).
# ============================================================================

# IAM Audit Logs: guarda logs de auditoría relacionados a cambios en IAM
resource "google_logging_project_bucket_config" "iam_audit_logs" {
  project        = var.project_id
  location       = "global"
  bucket_id      = "iam-audit-logs-${var.env}"
  retention_days = local.is_production ? 365 : 90
}

# Security Alerts: guarda logs relacionados a alertas de seguridad
resource "google_logging_project_bucket_config" "security_alerts" {
  project        = var.project_id
  location       = "global"
  bucket_id      = "security-alerts-${var.env}"
  retention_days = local.is_production ? 365 : 90
}

# Network Logs: guarda logs relacionados a la red (firewall, VPC, etc.)
resource "google_logging_project_bucket_config" "network_logs" {
  project        = var.project_id
  location       = "global"
  bucket_id      = "network-logs-${var.env}"
  retention_days = local.is_production ? 180 : 60
}

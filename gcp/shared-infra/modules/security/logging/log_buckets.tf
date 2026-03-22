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
  bucket_id      = "iam-audit-logs-${var.registry_name}-${var.env}${var.log_bucket_suffix}"
  retention_days = var.is_production ? 365 : 90

  lifecycle {
    # Ignorar cambios en buckets que están en estado no ACTIVE para evitar errores
    # Los buckets se crearán/modificarán cuando estén en estado ACTIVE
    ignore_changes = [
      retention_days,
    ]
    # Prevenir destrucción accidental: Los buckets solo se pueden eliminar cuando están en estado ACTIVE
    # Si necesitas eliminar un bucket, primero espera a que esté en estado ACTIVE o elimínalo manualmente
    # Para eliminar manualmente: terraform state rm 'module.security.module.logging.google_logging_project_bucket_config.iam_audit_logs'
    create_before_destroy = true
  }
}

# Security Alerts: guarda logs relacionados a alertas de seguridad
resource "google_logging_project_bucket_config" "security_alerts" {
  project        = var.project_id
  location       = "global"
  bucket_id      = "security-alerts-${var.registry_name}-${var.env}${var.log_bucket_suffix}"
  retention_days = var.is_production ? 365 : 90

  lifecycle {
    # Ignorar cambios en buckets que están en estado no ACTIVE para evitar errores
    # Los buckets se crearán/modificarán cuando estén en estado ACTIVE
    ignore_changes = [
      retention_days,
    ]
    # Si los buckets están en estado no ACTIVE y necesitas eliminarlos:
    # 1. Espera a que estén en estado ACTIVE, o
    # 2. Remueve del estado: terraform state rm 'module.security.module.logging.google_logging_project_bucket_config.security_alerts'
    # Ver README-LOGGING-BUCKETS.md para más detalles
    create_before_destroy = true
  }
}

# Network Logs: guarda logs relacionados a la red (firewall, VPC, etc.)
resource "google_logging_project_bucket_config" "network_logs" {
  project        = var.project_id
  location       = "global"
  bucket_id      = "network-logs-${var.registry_name}-${var.env}${var.log_bucket_suffix}"
  retention_days = var.is_production ? 180 : 60

  lifecycle {
    # Ignorar cambios en buckets que están en estado no ACTIVE para evitar errores
    # Los buckets se crearán/modificarán cuando estén en estado ACTIVE
    ignore_changes = [
      retention_days,
    ]
    # Si los buckets están en estado no ACTIVE y necesitas eliminarlos:
    # 1. Espera a que estén en estado ACTIVE, o
    # 2. Remueve del estado: terraform state rm 'module.security.module.logging.google_logging_project_bucket_config.network_logs'
    # Ver README-LOGGING-BUCKETS.md para más detalles
    create_before_destroy = true
  }
}

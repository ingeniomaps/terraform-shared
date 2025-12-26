
# ============================================================================
# ALERTING POLICIES
#
# Alertas automáticas para eventos críticos detectados por los sinks de Logging.
# Cada alerta envía notificaciones a los canales configurados y contiene documentación.
# ============================================================================

# Alerta por uso de la cuenta Break Glass
resource "google_monitoring_alert_policy" "break_glass_usage_alert" {
  display_name = "Break Glass Account Usage - ${upper(var.env)}"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Break Glass account is being used"
    condition_matched_log {
      filter = "protoPayload.authenticationInfo.principalEmail=\"${google_service_account.break_glass.email}\""
    }
  }

  notification_channels = var.alert_notification_channels

  alert_strategy {
    auto_close = "1800s" # Cierra automáticamente la alerta después de 30 minutos si no hay nuevos eventos
  }

  documentation {
    content   = "ALERTA CRÍTICA: La cuenta Break Glass está siendo utilizada en ${var.env}. Verificar inmediatamente con el equipo de seguridad."
    mime_type = "text/markdown"
  }
}

# Alerta por cambios en políticas IAM
resource "google_monitoring_alert_policy" "iam_policy_changes" {
  display_name = "IAM Policy Changes - ${upper(var.env)}"
  combiner     = "OR"
  enabled      = local.is_production # Solo activo en producción

  conditions {
    display_name = "IAM policy has been modified"
    condition_matched_log {
      filter = <<-EOT
        protoPayload.serviceName="iam.googleapis.com"
        AND protoPayload.methodName="SetIamPolicy"
      EOT
    }
  }

  notification_channels = var.alert_notification_channels

  alert_strategy {
    auto_close = "3600s" # Cierra la alerta después de 1 hora
  }

  documentation {
    content   = "Se han detectado cambios en políticas IAM en ${var.env}. Revisar los logs de auditoría."
    mime_type = "text/markdown"
  }
}

# Alerta por cambios en reglas de firewall
resource "google_monitoring_alert_policy" "firewall_rule_changes" {
  display_name = "Firewall Rule Changes - ${upper(var.env)}"
  combiner     = "OR"
  enabled      = local.is_production # Solo activo en producción

  conditions {
    display_name = "Firewall rules modified"
    condition_matched_log {
      filter = <<-EOT
        protoPayload.serviceName="compute.googleapis.com"
        AND protoPayload.methodName=~".*firewall.*"
        AND (protoPayload.methodName=~".*insert.*"
             OR protoPayload.methodName=~".*delete.*"
             OR protoPayload.methodName=~".*update.*"
             OR protoPayload.methodName=~".*patch.*")
      EOT
    }
  }

  notification_channels = var.alert_notification_channels

  alert_strategy {
    auto_close = "3600s"
  }

  documentation {
    content   = "Se han detectado cambios en reglas de firewall en ${var.env}. Verificar que sean autorizados."
    mime_type = "text/markdown"
  }
}

# Alerta por creación de llaves de cuentas de servicio (debería estar bloqueado)
resource "google_monitoring_alert_policy" "service_account_key_created" {
  display_name = "Service Account Key Created (Should be blocked) - ${upper(var.env)}"
  combiner     = "OR"
  enabled      = true

  conditions {
    display_name = "Service account key created"
    condition_matched_log {
      filter = <<-EOT
        protoPayload.serviceName="iam.googleapis.com"
        AND protoPayload.methodName="google.iam.admin.v1.CreateServiceAccountKey"
      EOT
    }
  }

  notification_channels = var.alert_notification_channels

  alert_strategy {
    auto_close = "1800s"
  }

  documentation {
    content   = "ALERTA: Intento de creación de llave de Service Account en ${var.env}. Esto debería estar bloqueado por org policy."
    mime_type = "text/markdown"
  }
}

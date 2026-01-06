# ============================================================================
# VARIABLES PARA EL MÓDULO LOGGING
# ============================================================================
variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "env" {
  description = "Ambiente (dev, stg, prod)"
  type        = string
}

variable "is_production" {
  description = "Indica si es ambiente de producción"
  type        = bool
}

variable "break_glass_email" {
  description = "Email de la Service Account Break Glass"
  type        = string
}

variable "registry_name" {
  description = "Nombre del Artifact Registry"
  type        = string
}


variable "alert_notification_channels" {
  description = "IDs de canales de notificación para alertas"
  type        = list(string)
  default     = []
}

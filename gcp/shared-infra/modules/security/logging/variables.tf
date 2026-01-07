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

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.break_glass_email))
    error_message = "break_glass_email debe ser un email válido (ej: sa@project.iam.gserviceaccount.com)"
  }
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

variable "log_bucket_suffix" {
  description = "Sufijo opcional para personalizar los nombres de los buckets de logging. Se agrega después del nombre del ambiente (ej: '-custom' resultaría en 'iam-audit-logs-dev-custom'). Si está vacío, no se agrega sufijo."
  type        = string
  default     = ""
}

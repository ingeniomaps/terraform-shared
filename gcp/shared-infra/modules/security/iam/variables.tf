# ============================================================================
# VARIABLES PARA EL MÓDULO IAM
# ============================================================================
variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "admin_groups" {
  description = "Grupos de administradores por rol"
  type = object({
    network_admins  = string
    network_viewers = string
    security_admins = string
    auditors        = string
  })
}

variable "ci_cd_writer_email" {
  description = "Email de la Service Account CI/CD"
  type        = string
}

variable "vm_reader_email" {
  description = "Email de la Service Account VM reader"
  type        = string
}

variable "break_glass_email" {
  description = "Email de la Service Account Break Glass"
  type        = string
}

variable "break_glass_max_session_duration" {
  description = "Duración máxima de sesión para break-glass (en segundos)"
  type        = number
  default     = 3600
}

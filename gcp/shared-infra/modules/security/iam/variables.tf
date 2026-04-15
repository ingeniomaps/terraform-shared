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

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.ci_cd_writer_email))
    error_message = "ci_cd_writer_email debe ser un email válido (ej: sa@project.iam.gserviceaccount.com)"
  }
}

variable "vm_reader_email" {
  description = "Email de la Service Account VM reader"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.vm_reader_email))
    error_message = "vm_reader_email debe ser un email válido (ej: sa@project.iam.gserviceaccount.com)"
  }
}

variable "break_glass_email" {
  description = "Email de la Service Account Break Glass"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.break_glass_email))
    error_message = "break_glass_email debe ser un email válido (ej: sa@project.iam.gserviceaccount.com)"
  }
}

variable "break_glass_max_session_duration" {
  description = "Duración máxima de sesión para break-glass (en segundos)"
  type        = number
  default     = 3600
}

variable "enable_group_iam" {
  description = "Habilitar asignación de roles IAM a grupos (requiere que los grupos existan en Google Workspace)"
  type        = bool
  default     = true
}

variable "create_vm_start_stop_role" {
  description = "Crear el custom role vmStartStop. Desactivar si se gestiona desde bootstrap."
  type        = bool
  default     = false
}

variable "create_audit_configs" {
  description = "Crear audit configs de proyecto. Desactivar si se gestiona desde bootstrap."
  type        = bool
  default     = false
}

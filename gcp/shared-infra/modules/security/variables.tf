variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "workspace" {
  description = "Nombre del workspace"
  type        = string
}

variable "env" {
  description = "Ambiente (dev, stg, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "stg", "pre", "prod"], var.env)
    error_message = "El ambiente debe ser dev, stg o prod"
  }
}

variable "registry_name" {
  description = "Nombre del Artifact Registry"
  type        = string
}

variable "registry_location" {
  description = "Ubicación del Artifact Registry"
  type        = string
}

variable "enable_dev_reader" {
  description = "Si es true, crea la cuenta de desarrollador"
  type        = bool
  default     = false
}

variable "enable_vpc_service_controls" {
  description = "Habilita VPC Service Controls (recomendado para prod)"
  type        = bool
  default     = false
}

variable "organization_id" {
  description = "ID de la organización de GCP"
  type        = string
}

variable "allowed_domains" {
  description = "Dominios permitidos para miembros IAM"
  type        = list(string)
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

variable "alert_notification_channels" {
  description = "IDs de canales de notificación para alertas"
  type        = list(string)
  default     = []
}

variable "break_glass_max_session_duration" {
  description = "Duración máxima de sesión para break-glass (en segundos)"
  type        = number
  default     = 3600 # 1 hora
}

variable "create_admin_sa" {
  description = "Controla si se crean las Service Accounts de administración y workload para GKE"
  type        = bool
  default     = false
}

variable "enable_group_iam" {
  description = "Habilitar asignación de roles IAM a grupos de Google Workspace (requiere que los grupos existan)"
  type        = bool
  default     = false
}

variable "enable_org_policies" {
  description = "Habilitar Organization Policies (requiere que orgpolicy.googleapis.com esté habilitado y configurado)"
  type        = bool
  default     = false
}
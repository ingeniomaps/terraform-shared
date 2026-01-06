# ============================================================================
# VARIABLES PARA EL MÓDULO SECURITY
# ============================================================================
variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "organization_id" {
  description = "ID de la organización de GCP"
  type        = string
}

variable "allowed_domains" {
  description = "Dominios permitidos para miembros IAM"
  type        = list(string)
}

variable "enable_vpc_service_controls" {
  description = "Habilita VPC Service Controls"
  type        = bool
  default     = false
}

variable "account_name" {
  description = "Nombre base de las cuentas (workspace-env-account)"
  type        = string
}

variable "workspace" {
  description = "Nombre del workspace"
  type        = string
}

variable "env" {
  description = "Ambiente (dev, stg, prod)"
  type        = string
}

variable "project_number" {
  description = "Número del proyecto de GCP"
  type        = string
}

variable "is_production" {
  description = "Indica si es ambiente de producción"
  type        = bool
}

variable "enable_org_policies" {
  description = "Habilitar Organization Policies (requiere que orgpolicy.googleapis.com esté habilitado y configurado)"
  type        = bool
  default     = false
}

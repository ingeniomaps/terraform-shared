variable "project_id" {
  description = "ID del proyecto en GCP"
  type        = string
}

variable "region" {
  description = "Región GCP"
  type        = string
  default     = "us-central1"
}

variable "credentials_file" {
  description = "Ruta al JSON de credenciales (opcional, relativa). Si no, GOOGLE_APPLICATION_CREDENTIALS o gcloud auth."
  type        = string
  default     = null
  sensitive   = true
}

variable "workspace" {
  description = "Nombre del workspace"
  type        = string
}

variable "env" {
  description = "Identidad del proyecto para nombres del perímetro (singleton; típicamente 'prod')"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "stg", "pre", "prod"], var.env)
    error_message = "env debe ser dev, qa, stg, pre o prod."
  }
}

variable "organization_id" {
  description = "ID de la organización de GCP"
  type        = string
}

variable "allowed_domains" {
  description = "Dominios permitidos para miembros IAM (org policy allowedPolicyMemberDomains)"
  type        = list(string)

  validation {
    condition = alltrue([
      for domain in var.allowed_domains : can(regex("^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\\.)+[a-zA-Z]{2,}$", domain))
    ])
    error_message = "Todos los dominios deben tener formato válido (ej: example.com)."
  }
}

variable "enable_org_policies" {
  description = "Habilitar Organization Policies (requiere orgpolicy.googleapis.com configurado)."
  type        = bool
  default     = false
}

variable "enable_vpc_service_controls" {
  description = "Habilitar VPC Service Controls (requiere Access Context Manager)."
  type        = bool
  default     = false
}

variable "enforce_prod_hardening" {
  description = "Exigir endurecimiento en prod (VPC-SC). false en el prod transicional; true cuando endurezca."
  type        = bool
  default     = true
}

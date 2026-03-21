# #########################################################
# Context
# #########################################################
variable "project_id" {
  description = "ID del proyecto en GCP"
  type        = string
}

variable "credentials_file" {
  description = "Ruta al archivo JSON de credenciales de Service Account (opcional). Ruta relativa desde la raíz del proyecto (ej: 'keys/account_service_{env}.json'). Si no se especifica, se usa GOOGLE_APPLICATION_CREDENTIALS o gcloud auth."
  type        = string
  default     = null
  sensitive   = true
}

variable "region" {
  description = "Región donde se desplegará la infraestructura"
  type        = string
  default     = "us-central1"
}

variable "env" {
  description = "Ambiente (dev, stg, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "qa", "stg", "pre", "prod"], var.env)
    error_message = "El ambiente debe ser dev, qa, stg, pre o prod."
  }
}

variable "workspace" {
  description = "Nombre del espacio de trabajo"
  type        = string
}

# #########################################################
# Security
# #########################################################
variable "registry_name" {
  description = "Nombre del Artifact Registry. Null = no crear (se crea en bootstrap/global)."
  type        = string
  default     = null
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

variable "break_glass_max_session_duration" {
  description = "Duración máxima de sesión para break-glass (en segundos)"
  type        = number
  default     = 3600
}

# #########################################################
# Alerting
# #########################################################
variable "alert_notification_channels" {
  description = "IDs de canales de notificación para alertas"
  type        = list(string)
  default     = []
}

# #########################################################
# Network
# #########################################################
variable "vm_subnet_cidr" {
  description = "CIDR de la subred para VMs"
  type        = string
  default     = "10.0.0.0/24"
}

variable "enable_public_http" {
  description = "Habilitar acceso HTTP/HTTPS público directo a VMs. En producción usar Load Balancer y desactivar esta regla."
  type        = bool
  default     = true
}

variable "enable_restricted_http" {
  description = "Habilitar acceso HTTP/HTTPS solo desde IPs corporativas. Mutuamente excluyente con enable_public_http."
  type        = bool
  default     = false
}

variable "corporate_ip_ranges" {
  description = "Rangos IP corporativos permitidos (requerido si enable_restricted_http = true). NUNCA usar 0.0.0.0/0 en producción."
  type        = list(string)
  default     = []

  validation {
    condition = (
      var.enable_restricted_http == false ||
      (var.enable_restricted_http == true && length(var.corporate_ip_ranges) > 0)
    )
    error_message = "corporate_ip_ranges es requerido y no puede estar vacío cuando enable_restricted_http = true."
  }

  validation {
    condition     = !contains(var.corporate_ip_ranges, "0.0.0.0/0")
    error_message = "corporate_ip_ranges no puede contener 0.0.0.0/0 — esto anula el propósito de restricted_http. Usa IPs reales de oficina/VPN/CI."
  }
}

# #########################################################
# Peering
# #########################################################
variable "enable_vpc_peering" {
  description = "Habilitar VPC peering"
  type        = bool
  default     = false
}

variable "peer_project_id" {
  description = "ID del proyecto peer (requerido si enable_vpc_peering = true)"
  type        = string
  default     = null

  validation {
    condition = (
      var.enable_vpc_peering == false ||
      (var.enable_vpc_peering == true && var.peer_project_id != null && var.peer_project_id != "")
    )
    error_message = "peer_project_id es requerido cuando enable_vpc_peering = true"
  }
}

variable "peer_vpc_name" {
  description = "Nombre de la VPC peer (requerido si enable_vpc_peering = true)"
  type        = string
  default     = null

  validation {
    condition = (
      var.enable_vpc_peering == false ||
      (var.enable_vpc_peering == true && var.peer_vpc_name != null && var.peer_vpc_name != "")
    )
    error_message = "peer_vpc_name es requerido cuando enable_vpc_peering = true"
  }
}

# #########################################################
# GKE
# #########################################################
variable "enable_gke" {
  description = "Habilitar subnet y firewall rules para GKE"
  type        = bool
  default     = false
}

variable "gke_subnet_cidr" {
  description = "CIDR principal para nodes de GKE"
  type        = string
  default     = "10.0.10.0/24" # 256 IPs para nodes
}

variable "gke_pods_cidr" {
  description = "CIDR secundario para pods de GKE"
  type        = string
  default     = "10.1.0.0/16" # 65k pods
}

variable "gke_services_cidr" {
  description = "CIDR secundario para services de GKE"
  type        = string
  default     = "10.2.0.0/16" # 65k services
}

variable "gke_master_cidr" {
  description = "CIDR para el control plane de GKE (debe ser /28)"
  type        = string
  default     = "172.16.0.0/28"

  validation {
    condition     = can(regex("^([0-9]{1,3}\\.){3}[0-9]{1,3}/28$", var.gke_master_cidr))
    error_message = "gke_master_cidr debe ser un CIDR válido con máscara /28"
  }
}

# #########################################################
# Security Options
# #########################################################
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

variable "log_bucket_suffix" {
  description = "Sufijo opcional para personalizar los nombres de los buckets de logging. Se agrega después del nombre del ambiente (ej: '-custom' resultaría en 'iam-audit-logs-{env}-custom'). Si está vacío, no se agrega sufijo."
  type        = string
  default     = ""
}
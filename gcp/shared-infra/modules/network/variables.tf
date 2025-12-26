# ============================================================================
# VARIABLES
# ============================================================================
variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "workspace" {
  description = "Nombre del workspace (ej: platform)"
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

variable "region" {
  description = "Región principal"
  type        = string
}

variable "vm_subnet_cidr" {
  description = "CIDR de la subred para VMs"
  type        = string
  default     = "10.0.0.0/24" # 256 IPs
}

variable "vm_service_account_email" {
  description = "Service Account usado por las VMs"
  type        = string
}

variable "enable_public_http" {
  description = "Habilitar acceso HTTP/HTTPS público (para load balancers)"
  type        = bool
  default     = true
}

variable "enable_restricted_http" {
  description = "Habilitar acceso HTTP/HTTPS solo desde IPs corporativas (mutuamente excluyente con enable_public_http)"
  type        = bool
  default     = false
}

variable "enable_vpc_peering" {
  description = "Habilitar VPC peering"
  type        = bool
  default     = false
}

variable "corporate_ip_ranges" {
  description = "Rangos IP corporativos (requerido si enable_restricted_http = true)"
  type        = list(string)
  default     = []
}

variable "peer_project_id" {
  description = "ID del proyecto peer (requerido si enable_vpc_peering = true)"
  type        = string
  default     = null
}

variable "peer_vpc_name" {
  description = "Nombre de la VPC peer (requerido si enable_vpc_peering = true)"
  type        = string
  default     = null
}

# ============================================================================
# VARIABLES PARA GKE
# ============================================================================
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

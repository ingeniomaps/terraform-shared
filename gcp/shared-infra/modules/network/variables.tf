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
    condition     = contains(["dev", "qa", "stg", "pre", "prod"], var.env)
    error_message = "El ambiente debe ser dev, qa, stg, pre o prod."
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

  validation {
    condition     = can(cidrhost(var.vm_subnet_cidr, 0))
    error_message = "vm_subnet_cidr debe ser un CIDR válido (ej: 10.0.0.0/24)"
  }
}

variable "vm_service_account_email" {
  description = "Service Account usado por las VMs"
  type        = string
}

variable "enable_public_http" {
  description = "Habilitar acceso HTTP/HTTPS público (para load balancers). Mutuamente excluyente con enable_restricted_http"
  type        = bool
  default     = true
}

variable "enable_restricted_http" {
  description = "Habilitar acceso HTTP/HTTPS solo desde IPs corporativas. Mutuamente excluyente con enable_public_http"
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

  validation {
    condition = (
      var.enable_restricted_http == false ||
      (var.enable_restricted_http == true && length(var.corporate_ip_ranges) > 0)
    )
    error_message = "corporate_ip_ranges es requerido y no puede estar vacío cuando enable_restricted_http = true"
  }
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

# ============================================================================
# VARIABLES PARA GKE
# ============================================================================
variable "enable_oslogin_metadata" {
  description = "Crear google_compute_project_metadata para OS Login. Desactivar si se gestiona desde bootstrap."
  type        = bool
  default     = false
}

variable "enable_gke" {
  description = "Habilitar subnet y firewall rules para GKE"
  type        = bool
  default     = false
}

variable "gke_subnet_cidr" {
  description = "CIDR principal para nodes de GKE"
  type        = string
  default     = "10.0.10.0/24" # 256 IPs para nodes

  validation {
    condition     = !var.enable_gke || can(cidrhost(var.gke_subnet_cidr, 0))
    error_message = "gke_subnet_cidr debe ser un CIDR válido cuando enable_gke = true"
  }
}

variable "gke_pods_cidr" {
  description = "CIDR secundario para pods de GKE"
  type        = string
  default     = "10.1.0.0/16" # 65k pods

  validation {
    condition     = !var.enable_gke || can(cidrhost(var.gke_pods_cidr, 0))
    error_message = "gke_pods_cidr debe ser un CIDR válido cuando enable_gke = true"
  }
}

variable "gke_services_cidr" {
  description = "CIDR secundario para services de GKE"
  type        = string
  default     = "10.2.0.0/16" # 65k services

  validation {
    condition     = !var.enable_gke || can(cidrhost(var.gke_services_cidr, 0))
    error_message = "gke_services_cidr debe ser un CIDR válido cuando enable_gke = true"
  }
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

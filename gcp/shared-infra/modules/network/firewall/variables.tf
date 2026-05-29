# ============================================================================
# VARIABLES PARA EL MÓDULO FIREWALL
# ============================================================================
variable "network_name" {
  description = "Nombre de la red (para prefijos de recursos)"
  type        = string
}

variable "vpc_name" {
  description = "Nombre de la VPC"
  type        = string
}

variable "vm_subnet_cidr" {
  description = "CIDR de la subred para VMs"
  type        = string
}

variable "vm_service_account_email" {
  description = "Service Account usado por las VMs"
  type        = string
}

variable "enable_public_http" {
  description = "Habilitar acceso HTTP/HTTPS público"
  type        = bool
  default     = false
}

variable "enable_restricted_http" {
  description = "Habilitar acceso HTTP/HTTPS restringido"
  type        = bool
  default     = false
}

variable "corporate_ip_ranges" {
  description = "Rangos IP corporativos"
  type        = list(string)
  default     = []
}

variable "enable_gke" {
  description = "Habilitar firewall rules para GKE"
  type        = bool
  default     = false
}

variable "gke_subnet_cidr" {
  description = "CIDR principal para nodes de GKE"
  type        = string
  default     = ""
}

variable "gke_pods_cidr" {
  description = "CIDR secundario para pods de GKE"
  type        = string
  default     = ""
}

variable "gke_services_cidr" {
  description = "CIDR secundario para services de GKE"
  type        = string
  default     = ""
}

variable "gke_master_cidr" {
  description = "CIDR para el control plane de GKE"
  type        = string
  default     = ""
}

variable "enable_direct_ssh" {
  description = "Crear la regla de SSH directo desde Internet (opt-in; menos seguro que IAP). Default: usar IAP."
  type        = bool
  default     = false
}

variable "ssh_direct_source_ranges" {
  description = "Rangos de origen para el SSH directo (requerido si enable_direct_ssh=true). NUNCA 0.0.0.0/0."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.ssh_direct_source_ranges, "0.0.0.0/0")
    error_message = "ssh_direct_source_ranges no puede contener 0.0.0.0/0 — usar IPs de oficina/VPN/bastion, o IAP."
  }
}

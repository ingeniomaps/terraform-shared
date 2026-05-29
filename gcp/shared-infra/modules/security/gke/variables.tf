# ============================================================================
# VARIABLES PARA EL MÓDULO GKE
# ============================================================================
variable "project_id" {
  description = "ID del proyecto de GCP"
  type        = string
}

variable "account_name" {
  description = "Nombre base de las cuentas (workspace-env-account)"
  type        = string
}

variable "create_admin_sa" {
  description = "Controla si se crean las Service Accounts de administración y workload para GKE"
  type        = bool
  default     = false
}

variable "registry_location" {
  description = "Ubicación del Artifact Registry"
  type        = string
}

variable "registry_name" {
  description = "Nombre del Artifact Registry"
  type        = string
}

variable "gke_workload_namespace" {
  description = "Namespace de la KSA vinculada por Workload Identity. NUNCA 'default' (cualquier pod sin KSA explícita lo heredaría)."
  type        = string
  default     = "workloads"
}

variable "gke_workload_ksa" {
  description = "Nombre de la KSA vinculada por Workload Identity. NUNCA 'default'."
  type        = string
  default     = "gke-workload"

  validation {
    condition     = !(var.gke_workload_namespace == "default" && var.gke_workload_ksa == "default")
    error_message = "No usar default/default para Workload Identity — usar un namespace/KSA dedicados."
  }
}

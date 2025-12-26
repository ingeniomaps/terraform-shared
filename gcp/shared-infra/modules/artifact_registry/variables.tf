variable "region" {
  description = "Región de GCP donde se creará el registry"
  type        = string
}

variable "repository_id" {
  description = "ID del repositorio (nombre único dentro de la región)"
  type        = string

  validation {
    condition     = can(regex("^[a-z]([a-z0-9-]{0,61}[a-z0-9])?$", var.repository_id))
    error_message = "El repository_id debe ser minúsculas, números y guiones, máximo 63 caracteres."
  }
}

variable "description" {
  description = "Descripción del repositorio"
  type        = string
  default     = ""
}

variable "labels" {
  description = "Labels para el repositorio"
  type        = map(string)
  default     = {}

  validation {
    condition     = alltrue([for k, v in var.labels : can(regex("^[a-z0-9_-]{1,63}$", k)) && can(regex("^[a-z0-9_-]{0,63}$", v))])
    error_message = "Los labels deben cumplir con el formato de GCP (lowercase, números, guiones y guiones bajos)."
  }
}

variable "readers" {
  description = "Lista de service accounts con permiso de lectura (pull). Formato: serviceAccount:EMAIL"
  type        = list(string)
  default     = []

#  validation {
#    condition     = alltrue([for m in var.readers : can(regex("^(serviceAccount|user|group):", m))])
#    error_message = "Los readers deben empezar con 'serviceAccount:', 'user:' o 'group:'."
#  }
}

variable "writers" {
  description = "Lista de service accounts con permiso de escritura (push). Formato: serviceAccount:EMAIL"
  type        = list(string)
  default     = []
}

variable "admins" {
  description = "Lista de service accounts con permisos de administración del registry. Formato: serviceAccount:EMAIL"
  type        = list(string)
  default     = []
}

variable "cleanup_policies" {
  description = "Políticas de limpieza automática de imágenes antiguas"
  type = list(object({
    id     = string
    action = string
    condition = optional(object({
      tag_state             = optional(string)
      tag_prefixes          = optional(list(string))
      older_than            = optional(string)
      newer_than            = optional(string)
      package_name_prefixes = optional(list(string))
    }))
    most_recent_versions = optional(object({
      package_name_prefixes = optional(list(string))
      keep_count            = optional(number)
    }))
  }))
  default = []
}

variable "enable_cleanup_policies" {
  description = "Controla si se crean las cleanup policies en el Artifact Registry"
  type        = bool
  default     = false
}
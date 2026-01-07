variable "bucket_name" {
  type        = string
  description = "Nombre del bucket"
}

variable "region" {
  type        = string
  description = "Región donde se creará el bucket"
}

variable "prevent_destroy" {
  type        = bool
  description = "Si es true, previene la destrucción accidental del bucket (recomendado para producción)"
  default     = true
}

variable "retention_period_days" {
  type        = number
  description = "Período de retención en días para los objetos del bucket (0 para deshabilitar)"
  default     = 30

  validation {
    condition     = var.retention_period_days >= 0
    error_message = "retention_period_days debe ser mayor o igual a 0"
  }
}

variable "retention_locked" {
  type        = bool
  description = "Si es true, bloquea la política de retención (no se puede modificar hasta que expire). Recomendado para producción"
  default     = false
}

variable "lifecycle_days_since_noncurrent" {
  type        = number
  description = "Número de días desde que un objeto se vuelve no actual antes de ser eliminado por la regla de lifecycle"
  default     = 365

  validation {
    condition     = var.lifecycle_days_since_noncurrent > 0
    error_message = "lifecycle_days_since_noncurrent debe ser mayor a 0"
  }
}

variable "lifecycle_num_newer_versions" {
  type        = number
  description = "Número de versiones más recientes a mantener antes de eliminar versiones antiguas"
  default     = 10

  validation {
    condition     = var.lifecycle_num_newer_versions > 0
    error_message = "lifecycle_num_newer_versions debe ser mayor a 0"
  }
}

variable "storage_class" {
  type        = string
  description = "Clase de almacenamiento del bucket. Valores: STANDARD, NEARLINE, COLDLINE, ARCHIVE"
  default     = "STANDARD"

  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "storage_class debe ser uno de: STANDARD, NEARLINE, COLDLINE, ARCHIVE"
  }
}
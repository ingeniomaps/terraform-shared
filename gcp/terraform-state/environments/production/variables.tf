variable "project_id" {
  description = "ID del proyecto en Google Cloud donde se desplegarán los recursos"
  type        = string
}

variable "region" {
  description = "Región de Google Cloud donde se crearán los recursos, por ejemplo, 'us-central1'."
  type        = string
  default     = "us-central1"  # Valor por defecto (puedes cambiarlo a la región que prefieras)
}

variable "bucket_prefix" {
  description = "Prefijo del nombre del bucket. Esto se usa para generar un nombre único para el bucket."
  type        = string
}

variable "env" {
  description = "Entorno para el que se desplegarán los recursos, por ejemplo, 'stg' o 'prod'."
  type        = string
  default     = "stg"  # Por defecto se asume el entorno 'stg' (puedes cambiarlo o sobrescribirlo)
}
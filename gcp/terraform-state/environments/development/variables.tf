variable "project_id" {
  description = "ID del proyecto en Google Cloud donde se desplegarán los recursos"
  type        = string
}

variable "credentials_file" {
  description = "Ruta al archivo JSON de credenciales de Service Account (opcional). Si no se especifica, se usa GOOGLE_APPLICATION_CREDENTIALS o gcloud auth. Ruta relativa desde la raíz del proyecto o absoluta."
  type        = string
  default     = null
  sensitive   = true
}

variable "region" {
  description = "Región de Google Cloud donde se crearán los recursos, por ejemplo, 'us-central1'."
  type        = string
  default     = "us-central1" # Valor por defecto (puedes cambiarlo a la región que prefieras)
}

variable "bucket_prefix" {
  description = "Prefijo del nombre del bucket. Esto se usa para generar un nombre único para el bucket."
  type        = string
}

variable "env" {
  description = "Entorno para el que se desplegarán los recursos, por ejemplo, 'dev', 'stg' o 'prod'."
  type        = string
  default     = "dev" # Por defecto se asume el entorno 'dev' (puedes cambiarlo o sobrescribirlo)
}

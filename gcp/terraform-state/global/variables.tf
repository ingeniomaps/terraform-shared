variable "project_id" {
  type        = string
  description = "ID del proyecto de GCP"
}

variable "credentials_file" {
  description = "Ruta al archivo JSON de credenciales de Service Account (opcional). Si no se especifica, se usa GOOGLE_APPLICATION_CREDENTIALS o gcloud auth. Ruta relativa desde la raíz del proyecto o absoluta."
  type        = string
  default     = null
  sensitive   = true
}

variable "bucket_name" {
  type        = string
  description = "Nombre del bucket de estado de Terraform"
}

variable "region" {
  description = "Región de Google Cloud donde se crearán los recursos, por ejemplo, 'us-central1'."
  type        = string
  default     = "us-central1" # Valor por defecto (puedes cambiarlo a la región que prefieras)
}
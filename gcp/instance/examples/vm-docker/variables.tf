variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región donde se creará la VM"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona donde se creará la VM"
  type        = string
  default     = "us-central1-a"
}

variable "credentials_file" {
  description = "Nombre del archivo JSON de credenciales (opcional, debe estar en ../keys/). Si no se especifica, se usa GOOGLE_APPLICATION_CREDENTIALS o gcloud auth."
  type        = string
  default     = null
  sensitive   = true
}

variable "shared_infra_state_bucket" {
  description = "Bucket donde está el estado de la infraestructura compartida"
  type        = string
}

variable "shared_infra_state_prefix" {
  description = "Prefijo del estado de la infraestructura compartida (ej: dev/shared/terraform)"
  type        = string
}

variable "instance_name" {
  description = "Nombre de la instancia VM"
  type        = string
  default     = "vm-docker-dev"
}

variable "machine_type" {
  description = "Tipo de máquina (ej: e2-medium, n1-standard-1)"
  type        = string
  default     = "e2-medium"
}

variable "tags" {
  description = "Network tags para la VM"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels para la VM"
  type        = map(string)
  default     = {}
}

variable "boot_disk_size" {
  description = "Tamaño del disco de arranque en GB"
  type        = number
  default     = 20
}

variable "boot_disk_type" {
  description = "Tipo de disco de arranque (pd-standard, pd-ssd)"
  type        = string
  default     = "pd-standard"
}

variable "enable_public_ip" {
  description = "Habilitar IP pública (requiere Cloud NAT si es false)"
  type        = bool
  default     = false
}

variable "static_public_ip" {
  description = "Nombre para crear una IP pública estática. Si es null, usa IP ephemeral."
  type        = string
  default     = null
}

variable "static_internal_ip" {
  description = "IP interna estática a asignar (debe estar en el rango de la subnet). Si es null, se asigna automáticamente."
  type        = string
  default     = null
}

variable "metadata_startup_script" {
  description = "Script de inicio personalizado (opcional, se agrega al script de Docker)"
  type        = string
  default     = ""
}

variable "ssh_keys" {
  description = "Claves SSH públicas para acceso (formato: usuario:clave)"
  type        = list(string)
  default     = []
  sensitive   = true
}

variable "install_docker_compose" {
  description = "Instalar Docker Compose"
  type        = bool
  default     = true
}

variable "install_certbot" {
  description = "Instalar Certbot para certificados SSL"
  type        = bool
  default     = false
}

variable "use_ubuntu_image" {
  description = "Usar imagen Ubuntu en lugar de Container-Optimized OS"
  type        = bool
  default     = true
}

variable "deployment_scripts" {
  description = "Ruta local a los scripts de despliegue a copiar a la VM (opcional)"
  type        = string
  default     = ""
}

variable "microservices" {
  description = "Lista de microservicios a desplegar automáticamente"
  type = list(object({
    name     = string
    repo_url = string
    branch   = string
    env_file = string
  }))
  default = []
}

variable "environment" {
  description = "Ambiente de despliegue (dev, qa, stg, prod)"
  type        = string
  default     = "dev"
}

# ==============================================================================
# VARIABLES — Módulo vm-topology
# ==============================================================================
# Módulo reutilizable que crea N VMs según la topología definida.
# Cada VM puede alojar uno o más servicios.
# ==============================================================================

# ------------------------------------------------------------------------------
# GCP
# ------------------------------------------------------------------------------

variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región GCP"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "Zona GCP"
  type        = string
  default     = "us-central1-a"
}

variable "credentials_file" {
  description = "Ruta al archivo de credenciales (relativa desde keys/). Opcional si se usa gcloud auth."
  type        = string
  default     = null
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Infraestructura compartida (remote state)
# ------------------------------------------------------------------------------

variable "shared_infra_state_bucket" {
  description = "Bucket GCS del estado de infra compartida. Null si se usan variables directas."
  type        = string
  default     = null
}

variable "shared_infra_state_prefix" {
  description = "Prefijo del estado de infra compartida."
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Red (se pueden obtener de remote state o especificar directamente)
# ------------------------------------------------------------------------------

variable "vm_subnet_name" {
  description = "Nombre de la subnet para VMs"
  type        = string
  default     = null
}

variable "service_account_email" {
  description = "Email de la Service Account para VMs"
  type        = string
  default     = null
}

# ------------------------------------------------------------------------------
# Ambiente
# ------------------------------------------------------------------------------

variable "environment" {
  description = "Ambiente de despliegue"
  type        = string

  validation {
    condition     = contains(["dev", "qa", "stg", "prod", "pruebas"], var.environment)
    error_message = "Ambiente debe ser: dev, qa, stg, prod o pruebas."
  }
}

variable "labels" {
  description = "Labels comunes para todas las VMs"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Network tags adicionales para todas las VMs"
  type        = list(string)
  default     = []
}

# ------------------------------------------------------------------------------
# SSH
# ------------------------------------------------------------------------------

variable "ssh_keys" {
  description = "Claves SSH públicas adicionales (formato: usuario:clave)"
  type        = list(string)
  default     = []
  sensitive   = true
}

# ------------------------------------------------------------------------------
# Topología — El corazón del módulo
# ------------------------------------------------------------------------------

variable "topology" {
  description = <<-EOT
    Mapa de VMs a crear. Cada key es el nombre del grupo, cada value define
    la máquina y qué servicios aloja.

    Ejemplo:
    topology = {
      "monolith" = {
        machine_type   = "e2-standard-4"
        boot_disk_size = 60
        services       = ["gateway", "backend-auth", "backend-platform"]
      }
    }
  EOT

  type = map(object({
    machine_type     = string
    boot_disk_size   = optional(number, 30)
    boot_disk_type   = optional(string, "pd-standard")
    enable_public_ip = optional(bool, true)
    static_public_ip = optional(string, null)
    install_certbot  = optional(bool, false)
    services         = list(string)
  }))
}

# ------------------------------------------------------------------------------
# Catálogo de servicios
# ------------------------------------------------------------------------------

variable "github_repo_base_url" {
  description = "URL base de repos con autenticación. Ej: https://user:token@github.com/org"
  type        = string
  sensitive   = true
}

variable "default_branch" {
  description = <<-EOT
    Rama por defecto para todos los servicios de este deploy.
    Cada proyecto define su propia rama sin necesitar conocer otros servicios.
    Si no se especifica, se usa "main".
  EOT

  type    = string
  default = "main"
}

variable "artifact_registry_url" {
  description = <<-EOT
    URL del Artifact Registry donde viven las imágenes Docker.
    Formato: REGION-docker.pkg.dev/PROJECT_ID/REPO_NAME

    Ejemplo: us-central1-docker.pkg.dev/PROJECT_ID/docker-repo
  EOT

  type    = string
  default = null
}

variable "default_image_tag" {
  description = "Tag por defecto de las imágenes Docker (ej: develop, latest, v1.0.0)"
  type        = string
  default     = "latest"
}

variable "service_overrides" {
  description = <<-EOT
    Overrides por servicio. Permite cambiar branch, launch_command, image_tag, etc.
    sin modificar el catálogo base. Solo se especifican los campos a sobreescribir.

    Ejemplo:
    service_overrides = {
      "gateway" = { image_tag = "v2.0.0" }
      "backend-platform" = { launch_command = "npm run start:debug" }
    }
  EOT

  type    = map(map(string))
  default = {}
}

# ------------------------------------------------------------------------------
# Scheduling — Encendido/apagado programado
# ------------------------------------------------------------------------------

variable "schedule" {
  description = <<-EOT
    Programación de encendido/apagado para ahorrar costos.
    Si enabled = false, las VMs corren 24/7.

    Ejemplo:
    schedule = {
      enabled  = true
      days     = "mon-fri"
      start    = "08:00"
      stop     = "20:00"
      timezone = "America/Bogota"
    }
  EOT

  type = object({
    enabled  = bool
    days     = optional(string, "mon-fri")
    start    = optional(string, "08:00")
    stop     = optional(string, "20:00")
    timezone = optional(string, "America/Bogota")
  })

  default = {
    enabled = false
  }
}

terraform {
  required_version = ">= 1.14.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0"
    }
  }

  # Por defecto usa backend local (estado en .terraform/).
  # Usa backend GCS (recomendado para producción):
  #
  # backend "gcs" {
  #   bucket = "tu-terraform-state-bucket"
  #   prefix = "instances/vm-artifact/dev"
  # }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.credentials_file != null ? file("${path.root}/../keys/${var.credentials_file}") : null
}

# Data sources para obtener información de la infraestructura compartida
data "terraform_remote_state" "shared_infra" {
  backend = "gcs"
  config = {
    bucket = var.shared_infra_state_bucket
    prefix = var.shared_infra_state_prefix
  }
}

module "vm_artifact" {
  # Módulo local (por defecto, para desarrollo)
  source = "../../modules/vm-artifact"

  # Opción 1: Módulo remoto desde tag/versión (recomendado para producción)
  # source = "git::https://github.com/tu-org/terraform-gcp.git//instance/modules/vm-artifact?ref=v1.0.0"

  # Opción 2: Módulo remoto desde branch (solo para desarrollo)
  # source = "git::https://github.com/tu-org/terraform-gcp.git//instance/modules/vm-artifact?ref=main"

  project_id            = var.project_id
  region                = var.region
  zone                  = var.zone
  instance_name         = var.instance_name
  machine_type          = var.machine_type
  vm_subnet_name        = data.terraform_remote_state.shared_infra.outputs.vm_subnet_name
  service_account_email = data.terraform_remote_state.shared_infra.outputs.vm_reader_email
  artifact_registry_url = data.terraform_remote_state.shared_infra.outputs.repository_url
  docker_image          = var.docker_image
  container_port        = var.container_port
  host_port             = var.host_port
  docker_env_vars       = var.docker_env_vars
  docker_command        = var.docker_command
  restart_policy        = var.restart_policy
  tags                  = var.tags
  labels                = var.labels
  boot_disk_size        = var.boot_disk_size
  boot_disk_type        = var.boot_disk_type
  enable_public_ip      = var.enable_public_ip
  static_public_ip      = var.static_public_ip
  static_internal_ip    = var.static_internal_ip
  use_ubuntu_image      = var.use_ubuntu_image
  health_check_path     = var.health_check_path
  health_check_port     = var.health_check_port
}

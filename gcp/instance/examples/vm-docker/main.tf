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
  #   prefix = "instances/vm-docker/dev"
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

module "vm_docker" {
  # Módulo local (por defecto, para desarrollo)
  source = "../../modules/vm-docker"

  # Opción 1: Módulo remoto desde tag/versión (recomendado para producción)
  # source = "git::https://github.com/tu-org/terraform-gcp.git//instance/modules/vm-docker?ref=v1.0.0"

  # Opción 2: Módulo remoto desde branch (solo para desarrollo)
  # source = "git::https://github.com/tu-org/terraform-gcp.git//instance/modules/vm-docker?ref=main"

  project_id              = var.project_id
  region                  = var.region
  zone                    = var.zone
  instance_name           = var.instance_name
  machine_type            = var.machine_type
  vm_subnet_name          = data.terraform_remote_state.shared_infra.outputs.vm_subnet_name
  service_account_email   = data.terraform_remote_state.shared_infra.outputs.vm_reader_email
  tags                    = var.tags
  labels                  = var.labels
  boot_disk_size          = var.boot_disk_size
  boot_disk_type          = var.boot_disk_type
  enable_public_ip        = var.enable_public_ip
  static_public_ip        = var.static_public_ip
  static_internal_ip      = var.static_internal_ip
  metadata_startup_script = var.metadata_startup_script
  ssh_keys                = var.ssh_keys
  install_docker_compose  = var.install_docker_compose
  install_certbot         = var.install_certbot
  use_ubuntu_image        = var.use_ubuntu_image
  deployment_scripts      = var.deployment_scripts
  microservices           = var.microservices
  environment             = var.environment
}

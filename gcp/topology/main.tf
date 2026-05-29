# ==============================================================================
# MÓDULO VM-TOPOLOGY
# ==============================================================================
# Crea N VMs según la topología definida, cada una con sus servicios.
# Usa for_each sobre var.topology para crear un módulo vm_docker por grupo.
# ==============================================================================

terraform {
  required_version = ">= 1.14.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.0"
    }
    null = {
      source  = "hashicorp/null"
      version = ">= 3.0"
    }
  }
}

# ==============================================================================
# DATA SOURCES
# ==============================================================================

data "terraform_remote_state" "shared_infra" {
  count = var.shared_infra_state_bucket != null && var.shared_infra_state_prefix != null ? 1 : 0

  backend = "gcs"
  config = {
    bucket = var.shared_infra_state_bucket
    prefix = var.shared_infra_state_prefix
  }
}

# ==============================================================================
# SSH — Clave generada por Terraform
# ==============================================================================

resource "tls_private_key" "vm_ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.vm_ssh_key.private_key_pem
  filename        = "${path.root}/keys/${var.environment}-ssh.pem"
  file_permission = "0600"
}

resource "local_file" "ssh_public_key" {
  content         = tls_private_key.vm_ssh_key.public_key_openssh
  filename        = "${path.root}/keys/${var.environment}-ssh.pub"
  file_permission = "0644"
}

# ==============================================================================
# VMs — Una por cada entry en topology
# ==============================================================================

module "vm" {
  for_each = var.topology

  # Módulo vm-docker local
  source = "../instance/modules/vm-docker"

  project_id              = var.project_id
  region                  = var.region
  zone                    = var.zone
  instance_name           = "${each.key}-${var.environment}"
  machine_type            = each.value.machine_type
  boot_disk_size          = each.value.boot_disk_size
  boot_disk_type          = each.value.boot_disk_type
  enable_public_ip        = each.value.enable_public_ip
  static_public_ip        = each.value.static_public_ip
  install_docker_compose  = true
  install_certbot         = each.value.install_certbot
  use_ubuntu_image        = true
  vm_subnet_name          = local.vm_subnet_name
  service_account_email   = local.service_account_email
  tags                    = local.tags_combined
  labels                  = merge(var.labels, { vm_group = each.key, environment = var.environment })
  ssh_keys                = local.ssh_keys_combined
  environment             = var.environment
  microservices           = local.vm_microservices[each.key]
  metadata_startup_script = var.metadata_startup_script
}

# ==============================================================================
# CHECKS — Validaciones
# ==============================================================================

check "required_values" {
  assert {
    condition     = local.vm_subnet_name != null
    error_message = "vm_subnet_name es requerido (vía variable directa o remote_state)."
  }

  assert {
    condition     = local.service_account_email != null
    error_message = "service_account_email es requerido (vía variable directa o remote_state)."
  }
}

check "valid_services" {
  assert {
    condition = alltrue([
      for vm_name, vm in var.topology :
      alltrue([
        for svc in vm.services :
        contains(keys(local.service_catalog_base), svc)
      ])
    ])
    error_message = "Uno o más servicios en topology no existen en el catálogo. Servicios válidos: ${join(", ", keys(local.service_catalog_base))}"
  }
}

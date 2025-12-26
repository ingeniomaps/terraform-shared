terraform {
  required_version = ">= 1.14.2"

  backend "gcs" {
    bucket      = "roax-terraform-state-stg"
    prefix      = "dev/shared/terraform"
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

module "security" {
  source   = "../../modules/security"

  project_id = var.project_id
  workspace  = var.workspace
  env        = var.env

  registry_name     = var.registry_name
  registry_location = var.region

  organization_id = var.organization_id
  allowed_domains = var.allowed_domains
  admin_groups    = var.admin_groups

  create_admin_sa             = false
  enable_dev_reader           = var.enable_dev_reader
  enable_vpc_service_controls = var.enable_vpc_service_controls

  alert_notification_channels = var.alert_notification_channels

  break_glass_max_session_duration = var.break_glass_max_session_duration
}

module "artifact_registry" {
  source = "../../modules/artifact_registry"

  region        = var.region
  repository_id = var.registry_name
  description   = "Repositorio Docker compartido para ${var.workspace}"

  enable_cleanup_policies = false

  labels = {
    environment = "shared"
    managed_by  = "terraform"
    workspace   = var.workspace
    environment = var.env
  }

  readers = compact([
    module.security.vm_reader_email,
    var.enable_dev_reader ? module.security.dev_reader_email : null
  ])

  writers = compact([
    module.security.ci_cd_writer_email,
    var.enable_dev_reader ? module.security.dev_reader_email : null
  ])
}

module "network" {
  source = "../../modules/network"

  project_id = var.project_id
  workspace  = var.workspace
  region     = var.region
  env        = var.env

  # subnet
  vm_subnet_cidr    = var.vm_subnet_cidr
  enable_gke        = var.enable_gke
  gke_subnet_cidr   = var.gke_subnet_cidr
  gke_pods_cidr     = var.gke_pods_cidr
  gke_services_cidr = var.gke_services_cidr

  # firewall
  vm_service_account_email    = module.security.vm_reader_email
  enable_public_http          = var.enable_public_http
  enable_restricted_http      = var.enable_restricted_http
  corporate_ip_ranges         = var.corporate_ip_ranges
  gke_master_cidr             = var.gke_master_cidr

  # vpc_peering
  peer_project_id = var.peer_project_id
  peer_vpc_name   = var.peer_vpc_name
}

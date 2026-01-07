# ============================================================================
# MÓDULO FIREWALL
# ============================================================================
module "firewall" {
  source = "./firewall"

  network_name             = local.network_name
  vpc_name                 = google_compute_network.vpc.name
  vm_subnet_cidr           = var.vm_subnet_cidr
  vm_service_account_email = var.vm_service_account_email
  enable_public_http       = var.enable_public_http
  enable_restricted_http   = var.enable_restricted_http
  corporate_ip_ranges      = var.corporate_ip_ranges
  enable_gke               = var.enable_gke
  gke_subnet_cidr          = var.gke_subnet_cidr
  gke_pods_cidr            = var.gke_pods_cidr
  gke_services_cidr        = var.gke_services_cidr
  gke_master_cidr          = var.gke_master_cidr
}

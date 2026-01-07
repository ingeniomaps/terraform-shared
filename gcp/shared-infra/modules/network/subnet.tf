# ============================================================================
# SUBNET PARA VMs TRADICIONALES
# ============================================================================
resource "google_compute_subnetwork" "vm_subnet" {
  name          = "${local.network_name}-vm-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.vm_subnet_cidr

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  description = "Subred para VMs en ${var.env}"
}

# ============================================================================
# SUBNET PARA GKE (con secondary ranges)
# ============================================================================
resource "google_compute_subnetwork" "gke_subnet" {
  count = var.enable_gke ? 1 : 0

  name          = "${local.network_name}-gke-subnet"
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.gke_subnet_cidr

  secondary_ip_range {
    range_name    = "${local.network_name}-pods"
    ip_cidr_range = var.gke_pods_cidr
  }

  secondary_ip_range {
    range_name    = "${local.network_name}-services"
    ip_cidr_range = var.gke_services_cidr
  }

  private_ip_google_access = true

  log_config {
    aggregation_interval = "INTERVAL_10_MIN"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }

  description = "Subred para GKE cluster en ${var.env}"
}
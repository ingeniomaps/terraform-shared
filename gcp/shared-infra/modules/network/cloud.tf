
# ============================================================================
# CLOUD ROUTER
# ============================================================================
resource "google_compute_router" "router" {
  name    = "${local.network_name}-router"
  region  = var.region
  network = google_compute_network.vpc.id

  bgp {
    asn = 64514
  }
}

# ============================================================================
# CLOUD NAT
# ============================================================================
resource "google_compute_router_nat" "nat" {
  name   = "${local.network_name}-nat"
  router = google_compute_router.router.name
  region = var.region

  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
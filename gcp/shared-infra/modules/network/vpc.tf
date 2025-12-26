# ============================================================================
# VPC PRINCIPAL
# ============================================================================
resource "google_compute_network" "vpc" {
  name                    = "${local.network_name}-vpc"
  auto_create_subnetworks = false
  routing_mode            = "GLOBAL"

  description = "VPC para ${var.workspace} en ambiente ${var.env}"
}

# ============================================================================
# VPC PEERING (OPCIONAL)
# ============================================================================
resource "google_compute_network_peering" "peer_to_b" {
  count = var.enable_vpc_peering ? 1 : 0

  name         = "${local.network_name}-to-${var.peer_vpc_name}"
  network      = google_compute_network.vpc.name
  peer_network = "projects/${var.peer_project_id}/global/networks/${var.peer_vpc_name}"

  export_custom_routes = true
  import_custom_routes = true

  depends_on = [google_compute_network.vpc]
}

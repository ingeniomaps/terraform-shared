# ============================================================================
# OUTPUTS
# ============================================================================
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "Nombre de la VPC"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "Self link de la VPC"
  value       = google_compute_network.vpc.self_link
}

output "vm_subnet_id" {
  description = "ID de la subnet para VMs"
  value       = google_compute_subnetwork.vm_subnet.id
}

output "vm_subnet_cidr" {
  description = "CIDR de la subnet para VMs"
  value       = google_compute_subnetwork.vm_subnet.ip_cidr_range
}

output "vm_subnet_name" {
  description = "Nombre de la subnet para VMs"
  value       = google_compute_subnetwork.vm_subnet.name
}

output "gke_subnet_id" {
  description = "ID de la subnet GKE (null si GKE no está habilitado)"
  value       = var.enable_gke ? google_compute_subnetwork.gke_subnet[0].id : null
}

output "gke_subnet_name" {
  description = "Nombre de la subnet GKE"
  value       = var.enable_gke ? google_compute_subnetwork.gke_subnet[0].name : null
}

output "gke_pods_range_name" {
  description = "Nombre del secondary range para pods"
  value       = var.enable_gke ? "${local.network_name}-pods" : null
}

output "gke_services_range_name" {
  description = "Nombre del secondary range para services"
  value       = var.enable_gke ? "${local.network_name}-services" : null
}

output "cloud_nat_name" {
  description = "Nombre del Cloud NAT"
  value       = google_compute_router_nat.nat.name
}

output "cloud_router_name" {
  description = "Nombre del Cloud Router"
  value       = google_compute_router.router.name
}

output "network_tags" {
  description = "Network tags que deben usarse en recursos"
  value = {
    gke_nodes = var.enable_gke ? "gke-${local.network_name}" : null
  }
}
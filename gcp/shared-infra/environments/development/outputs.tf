# ============================================================================
# OUTPUTS - Network
# ============================================================================
output "vpc_id" {
  description = "ID de la VPC creada"
  value       = module.network.vpc_id
}

output "vpc_name" {
  description = "Nombre de la VPC"
  value       = module.network.vpc_name
}

output "vpc_self_link" {
  description = "Self link de la VPC"
  value       = module.network.vpc_self_link
}

output "vm_subnet_id" {
  description = "ID de la subnet para VMs"
  value       = module.network.vm_subnet_id
}

output "vm_subnet_cidr" {
  description = "CIDR de la subnet para VMs"
  value       = module.network.vm_subnet_cidr
}

output "vm_subnet_name" {
  description = "Nombre de la subnet para VMs"
  value       = module.network.vm_subnet_name
}

output "gke_subnet_id" {
  description = "ID de la subnet GKE (null si GKE no está habilitado)"
  value       = module.network.gke_subnet_id
}

output "gke_subnet_name" {
  description = "Nombre de la subnet GKE"
  value       = module.network.gke_subnet_name
}

output "gke_pods_range_name" {
  description = "Nombre del secondary range para pods"
  value       = module.network.gke_pods_range_name
}

output "gke_services_range_name" {
  description = "Nombre del secondary range para services"
  value       = module.network.gke_services_range_name
}

output "cloud_nat_name" {
  description = "Nombre del Cloud NAT"
  value       = module.network.cloud_nat_name
}

output "cloud_router_name" {
  description = "Nombre del Cloud Router"
  value       = module.network.cloud_router_name
}

output "network_name" {
  description = "Nombre de la red (workspace-env)"
  value       = module.network.network_name
}

output "network_tags" {
  description = "Network tags que deben usarse en recursos (incluye allow_iap_ssh y allow_ssh)"
  value       = module.network.network_tags
}

# ============================================================================
# OUTPUTS - Security
# ============================================================================
output "ci_cd_writer_email" {
  description = "Email de la cuenta CI/CD"
  value       = module.security.ci_cd_writer_email
}

output "vm_reader_email" {
  description = "Email de la cuenta VM reader"
  value       = module.security.vm_reader_email
}

output "dev_reader_email" {
  description = "Email de la cuenta de developers (null si deshabilitado)"
  value       = module.security.dev_reader_email
}

output "break_glass_email" {
  description = "Email de la cuenta Break Glass"
  value       = module.security.break_glass_email
  sensitive   = true
}

# ============================================================================
# OUTPUTS - Artifact Registry
# ============================================================================
output "repository_name" {
  description = "Nombre completo del repositorio"
  value       = module.artifact_registry.repository_name
}

output "repository_url" {
  description = "URL completa del repositorio para Docker pull/push"
  value       = module.artifact_registry.repository_url
}

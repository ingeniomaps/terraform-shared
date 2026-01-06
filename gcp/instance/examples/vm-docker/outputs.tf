# ============================================================================
# OUTPUTS: Re-exportar outputs del módulo vm-docker
# ============================================================================

output "instance_id" {
  description = "ID de la instancia VM"
  value       = module.vm_docker.instance_id
}

output "instance_name" {
  description = "Nombre de la instancia VM"
  value       = module.vm_docker.instance_name
}

output "instance_zone" {
  description = "Zona de la instancia"
  value       = module.vm_docker.instance_zone
}

output "internal_ip" {
  description = "IP interna de la instancia"
  value       = module.vm_docker.internal_ip
}

output "external_ip" {
  description = "IP externa de la instancia (null si no tiene IP pública). Si se usa IP estática, contiene la dirección de la IP estática."
  value       = module.vm_docker.external_ip
}

output "static_public_ip_name" {
  description = "Nombre del recurso de IP pública estática (null si no se usa IP estática). Útil para referenciar el recurso directamente."
  value       = module.vm_docker.static_public_ip_name
}

output "self_link" {
  description = "Self link de la instancia"
  value       = module.vm_docker.self_link
}

output "ssh_command" {
  description = "Comando SSH para conectarse vía IAP (si no tiene IP pública) o directamente (si tiene IP pública)"
  value       = module.vm_docker.ssh_command
}

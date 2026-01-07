# ============================================================================
# OUTPUTS: Re-exportar outputs del módulo vm-artifact
# ============================================================================

output "instance_id" {
  description = "ID de la instancia VM"
  value       = module.vm_artifact.instance_id
}

output "instance_name" {
  description = "Nombre de la instancia VM"
  value       = module.vm_artifact.instance_name
}

output "instance_zone" {
  description = "Zona de la instancia"
  value       = module.vm_artifact.instance_zone
}

output "internal_ip" {
  description = "IP interna de la instancia"
  value       = module.vm_artifact.internal_ip
}

output "external_ip" {
  description = "IP externa de la instancia (null si no tiene IP pública). Si se usa IP estática, contiene la dirección de la IP estática."
  value       = module.vm_artifact.external_ip
}

output "static_public_ip_name" {
  description = "Nombre del recurso de IP pública estática (null si no se usa IP estática). Útil para referenciar el recurso directamente."
  value       = module.vm_artifact.static_public_ip_name
}

output "self_link" {
  description = "Self link de la instancia"
  value       = module.vm_artifact.self_link
}

output "ssh_command" {
  description = "Comando SSH para conectarse vía IAP (si no tiene IP pública) o directamente (si tiene IP pública)"
  value       = module.vm_artifact.ssh_command
}

output "docker_image_path" {
  description = "Ruta completa de la imagen Docker en Artifact Registry"
  value       = module.vm_artifact.docker_image_path
}

output "container_url" {
  description = "URL para acceder al contenedor (si tiene IP pública)"
  value       = module.vm_artifact.container_url
}

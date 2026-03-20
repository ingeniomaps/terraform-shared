# ==============================================================================
# OUTPUTS — Información de las VMs creadas
# ==============================================================================

output "vms" {
  description = "Información de cada VM creada por la topología"
  value = {
    for vm_name, vm in module.vm : vm_name => {
      instance_name = "${vm_name}-${var.environment}"
      instance_id   = vm.instance_id
      internal_ip   = vm.internal_ip
      external_ip   = try(vm.external_ip, null)
      ssh_command   = try(vm.ssh_command, null)
      services      = var.topology[vm_name].services
    }
  }
}

output "ssh_private_key_path" {
  description = "Ruta a la clave SSH privada generada"
  value       = local_file.ssh_private_key.filename
}

output "environment" {
  description = "Ambiente desplegado"
  value       = var.environment
}

output "topology_summary" {
  description = "Resumen de la topología desplegada"
  value = {
    for vm_name, vm in var.topology : vm_name => {
      machine_type = vm.machine_type
      services     = vm.services
      num_services = length(vm.services)
    }
  }
}

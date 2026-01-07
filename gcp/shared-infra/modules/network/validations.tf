# ============================================================================
# VALIDACIONES ADICIONALES PARA CALIDAD DE CÓDIGO
# ============================================================================

# Validación: Verificar que los CIDR ranges no se solapen
locals {
  # Convertir CIDR a números para comparación
  cidr_to_number = {
    vm_subnet    = try(cidrhost(var.vm_subnet_cidr, 0), null)
    gke_subnet   = var.enable_gke ? try(cidrhost(var.gke_subnet_cidr, 0), null) : null
    gke_pods     = var.enable_gke ? try(cidrhost(var.gke_pods_cidr, 0), null) : null
    gke_services = var.enable_gke ? try(cidrhost(var.gke_services_cidr, 0), null) : null
  }
}

# Validación: CIDR ranges deben tener formato válido
check "cidr_format_validation" {
  assert {
    condition     = can(cidrhost(var.vm_subnet_cidr, 0))
    error_message = "vm_subnet_cidr debe ser un CIDR válido (ej: 10.0.0.0/24)"
  }

  assert {
    condition     = !var.enable_gke || can(cidrhost(var.gke_subnet_cidr, 0))
    error_message = "gke_subnet_cidr debe ser un CIDR válido cuando enable_gke = true"
  }

  assert {
    condition     = !var.enable_gke || can(cidrhost(var.gke_pods_cidr, 0))
    error_message = "gke_pods_cidr debe ser un CIDR válido cuando enable_gke = true"
  }

  assert {
    condition     = !var.enable_gke || can(cidrhost(var.gke_services_cidr, 0))
    error_message = "gke_services_cidr debe ser un CIDR válido cuando enable_gke = true"
  }
}

# Validación: Service Account email debe tener formato válido
check "service_account_email_format" {
  assert {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.vm_service_account_email))
    error_message = "vm_service_account_email debe ser un email válido (ej: sa@project.iam.gserviceaccount.com)"
  }
}

# Validación: Corporate IP ranges deben tener formato CIDR válido
check "corporate_ip_ranges_format" {
  assert {
    condition = length(var.corporate_ip_ranges) == 0 || alltrue([
      for cidr in var.corporate_ip_ranges : can(cidrhost(cidr, 0))
    ])
    error_message = "Todos los valores en corporate_ip_ranges deben ser CIDR válidos"
  }
}

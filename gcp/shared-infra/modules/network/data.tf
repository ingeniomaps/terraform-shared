# ============================================================================
# LOCALS
# ============================================================================
locals {
  network_name = "${var.workspace}-${var.env}"

  common_labels = {
    environment = var.env
    workspace   = var.workspace
    managed_by  = "terraform"
  }

  # Validación: no puedes tener ambas reglas HTTP activas
  http_config_valid = !(var.enable_public_http && var.enable_restricted_http)
}

# Validación a nivel de configuración
resource "null_resource" "validate_http_config" {
  count = local.http_config_valid ? 0 : 1

  provisioner "local-exec" {
    command = "echo 'ERROR: enable_public_http y enable_restricted_http no pueden ser true al mismo tiempo' && exit 1"
  }
}

# ============================================================================
# PROJECT METADATA: OS LOGIN
# ============================================================================
resource "google_compute_project_metadata" "enable_oslogin" {
  metadata = {
    enable-oslogin = "TRUE"
  }
}

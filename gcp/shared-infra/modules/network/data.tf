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
}

# Validación: enable_public_http y enable_restricted_http son mutuamente excluyentes
check "http_access_exclusivity" {
  assert {
    condition     = !(var.enable_public_http && var.enable_restricted_http)
    error_message = "enable_public_http y enable_restricted_http no pueden ser true al mismo tiempo"
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

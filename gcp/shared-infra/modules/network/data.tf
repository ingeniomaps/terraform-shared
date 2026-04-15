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
# Gestionado por bootstrap/global. Solo crear si enable_oslogin_metadata = true
# (para retrocompatibilidad con ambientes que aún no migraron a bootstrap).
moved {
  from = google_compute_project_metadata.enable_oslogin
  to   = google_compute_project_metadata.enable_oslogin[0]
}

resource "google_compute_project_metadata" "enable_oslogin" {
  count = var.enable_oslogin_metadata ? 1 : 0
  metadata = {
    enable-oslogin = "TRUE"
  }
}

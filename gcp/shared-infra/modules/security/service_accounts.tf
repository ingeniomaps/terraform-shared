# ============================================================================
# SERVICE ACCOUNTS: Cuentas de servicio utilizadas en el proyecto
# ============================================================================

# Esta cuenta se usa para hacer push de imágenes Docker
resource "google_service_account" "ci_cd_writer" {
  account_id   = "${local.account_name}-ci-cd-writer"
  display_name = "CI/CD service account to push Docker images (${var.env})"
  description  = "Service Account para pipeline CI/CD - push de imágenes en ${var.env}"
}

# Permite a las máquinas virtuales hacer pull de imágenes desde Artifact Registry
resource "google_service_account" "vm_reader" {
  account_id   = "${local.account_name}-vm-reader"
  display_name = "VM service account to pull Docker images (${var.env})"
  description  = "Service Account para VMs - pull de imágenes en ${var.env}"
}

# Cuenta de servicio opcional para desarrolladores
# Se habilita solo si enable_dev_reader = true
resource "google_service_account" "dev_reader" {
  count        = var.enable_dev_reader ? 1 : 0
  account_id   = "${local.account_name}-dev-reader"
  display_name = "Developer service account to pull Docker images (${var.env})"
  description  = "Service Account para desarrolladores - solo lectura en ${var.env}"
}

# Cuenta de emergencia con permisos especiales de administración temporal
resource "google_service_account" "break_glass" {
  account_id   = "${local.account_name}-break-glass"
  display_name = "Break Glass Emergency Account (${var.env})"
  description  = "Cuenta de emergencia para recuperación de desastres en ${var.env} - USO RESTRINGIDO"
}

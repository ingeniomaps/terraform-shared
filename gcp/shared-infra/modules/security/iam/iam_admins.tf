# ============================================================================
# IAM – ADMINISTRADORES Y AUDITORES (GRUPOS)
#
# Asignación de roles IAM a grupos corporativos.
# Se utiliza google_project_iam_member para evitar sobrescribir bindings
# y permitir una gestión granular y segura de permisos.
# ============================================================================

# Administradores con control total sobre redes, subredes, firewalls y rutas.
resource "google_project_iam_member" "network_admin" {
  count = var.enable_group_iam ? 1 : 0

  project = var.project_id
  role    = "roles/compute.networkAdmin"
  member  = "group:${var.admin_groups.network_admins}"
}

# Acceso de solo lectura a recursos de red (sin capacidad de modificación).
# Útil para equipos de soporte, arquitectura o troubleshooting.
resource "google_project_iam_member" "network_viewer" {
  count = var.enable_group_iam ? 1 : 0

  project = var.project_id
  role    = "roles/compute.networkViewer"
  member  = "group:${var.admin_groups.network_viewers}"
}

# Permite administrar configuraciones de seguridad a nivel de Compute Engine
# (firewalls, políticas de seguridad, reglas avanzadas).
resource "google_project_iam_member" "security_admin" {
  count = var.enable_group_iam ? 1 : 0

  project = var.project_id
  role    = "roles/compute.securityAdmin"
  member  = "group:${var.admin_groups.security_admins}"
}

# Permite administrar políticas de firewall a nivel de organización
# aplicadas al proyecto (más restrictivo que firewall tradicional).
resource "google_project_iam_member" "org_firewall_policy_admin" {
  count = var.enable_group_iam ? 1 : 0

  project = var.project_id
  role    = "roles/compute.orgFirewallPolicyAdmin"
  member  = "group:${var.admin_groups.security_admins}"
}

# Permite gestionar permisos, bindings IAM y configuraciones sensibles
# relacionadas con identidades dentro del proyecto.
resource "google_project_iam_member" "iam_security_admin" {
  count = var.enable_group_iam ? 1 : 0

  project = var.project_id
  role    = "roles/iam.securityAdmin"
  member  = "group:${var.admin_groups.security_admins}"
}


# ============================================================================
# AUDITORES
#
# Acceso de solo lectura orientado a auditoría, compliance y monitoreo.
# No permite modificaciones en recursos del proyecto.
# ============================================================================

# Acceso de solo lectura general a recursos del proyecto.
resource "google_project_iam_member" "auditor_viewer" {
  count = var.enable_group_iam ? 1 : 0

  project = var.project_id
  role    = "roles/viewer"
  member  = "group:${var.admin_groups.auditors}"
}

# Permite revisar configuraciones y políticas IAM sin poder modificarlas.
resource "google_project_iam_member" "security_reviewer" {
  count = var.enable_group_iam ? 1 : 0

  project = var.project_id
  role    = "roles/iam.securityReviewer"
  member  = "group:${var.admin_groups.auditors}"
}

# Permite acceso de lectura a logs estándar del proyecto.
resource "google_project_iam_member" "log_viewer" {
  count = var.enable_group_iam ? 1 : 0

  project = var.project_id
  role    = "roles/logging.viewer"
  member  = "group:${var.admin_groups.auditors}"
}

# Permite acceso a logs privados/sensibles (ej. Data Access logs).
# Es crítico para auditorías de seguridad y cumplimiento normativo.
resource "google_project_iam_member" "private_log_viewer" {
  count = var.enable_group_iam ? 1 : 0

  project = var.project_id
  role    = "roles/logging.privateLogViewer"
  member  = "group:${var.admin_groups.auditors}"
}
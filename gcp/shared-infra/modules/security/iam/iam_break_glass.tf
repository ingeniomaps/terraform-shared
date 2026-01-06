# ============================================================================
# BREAK GLASS – CUENTA DE EMERGENCIA
#
# La cuenta Break Glass se utiliza exclusivamente para escenarios de emergencia
# Su uso debe ser excepcional, auditado y monitoreado.
# ============================================================================
# IMPORTANTE:
# - No se asigna el rol Owner.
# - Los permisos están explícitamente definidos y limitados.
# - Todo uso debe generar alertas y quedar registrado en logs de auditoría.


# Mapa de roles de break-glass con sus descripciones.
# La clave es el rol IAM, y el valor es la descripción del propósito del rol.
locals {
  break_glass_roles = {
    "roles/compute.admin"        = "Permite administración completa de Compute Engine"
    "roles/compute.networkAdmin" = "Permite modificar firewalls y rutas"
    "roles/iam.securityAdmin"    = "Permite gestionar permisos IAM críticos"
    "roles/storage.admin"        = "Acceso administrativo a Cloud Storage"
  }
}

# Recurso IAM para asignar los roles de break-glass a la cuenta de servicio.
# Se usa for_each para iterar sobre el mapa local, evitando duplicación de código.
resource "google_project_iam_member" "break_glass" {
  for_each = local.break_glass_roles

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${var.break_glass_email}"

  # Condición IAM para limitar el acceso en el tiempo
  condition {
    title       = "break_glass_time_limited"
    description = each.value
    expression  = "request.time < timestamp('${timeadd(timestamp(), "${var.break_glass_max_session_duration}s")}')"
  }
}
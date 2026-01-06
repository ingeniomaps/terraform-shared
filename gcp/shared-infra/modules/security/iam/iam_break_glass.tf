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

# Timestamp estático para la condición IAM de break-glass
# Se genera una vez y persiste hasta que se fuerza su rotación con terraform taint
# Esto evita que la condición cambie en cada terraform plan/apply
resource "time_static" "break_glass_expiry" {
  # El timestamp se genera una vez y solo cambia si se fuerza con terraform taint
  # o si se destruye y recrea el recurso
}

# Calcula la fecha de expiración sumando la duración máxima de sesión al timestamp estático
locals {
  break_glass_expiry_timestamp = timeadd(time_static.break_glass_expiry.rfc3339, "${var.break_glass_max_session_duration}s")
}

# Recurso IAM para asignar los roles de break-glass a la cuenta de servicio.
# Se usa for_each para iterar sobre el mapa local, evitando duplicación de código.
resource "google_project_iam_member" "break_glass" {
  for_each = local.break_glass_roles

  project = var.project_id
  role    = each.key
  member  = "serviceAccount:${var.break_glass_email}"

  # Condición IAM para limitar el acceso en el tiempo
  # Usa el timestamp estático para evitar cambios constantes en terraform plan
  condition {
    title       = "break_glass_time_limited"
    description = each.value
    expression  = "request.time < timestamp('${local.break_glass_expiry_timestamp}')"
  }
}
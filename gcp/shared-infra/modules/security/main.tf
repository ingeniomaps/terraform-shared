# ============================================================================
# MÓDULO SECURITY - ESTRUCTURA PRINCIPAL
# ============================================================================
#
# Este módulo gestiona la seguridad del proyecto:
# - Service Accounts (service_accounts.tf)
# - IAM (módulo iam/)
# - Logging (módulo logging/)
# - Security policies (módulo security/)
# - GKE (módulo gke/)
# - Validaciones y locals (data.tf)
#
# ============================================================================

# ============================================================================
# MÓDULO IAM
# ============================================================================
module "iam" {
  source = "./iam"

  project_id                       = var.project_id
  admin_groups                     = var.admin_groups
  ci_cd_writer_email               = google_service_account.ci_cd_writer.email
  vm_reader_email                  = google_service_account.vm_reader.email
  break_glass_email                = google_service_account.break_glass.email
  break_glass_max_session_duration = var.break_glass_max_session_duration
  enable_group_iam                 = var.enable_group_iam
  create_vm_start_stop_role        = var.create_vm_start_stop_role
  create_audit_configs             = var.create_audit_configs
}

# ============================================================================
# MÓDULO LOGGING
# ============================================================================
module "logging" {
  source = "./logging"

  project_id                  = var.project_id
  env                         = var.env
  is_production               = local.is_production
  break_glass_email           = google_service_account.break_glass.email
  registry_name               = var.registry_name
  alert_notification_channels = var.alert_notification_channels
  log_bucket_suffix           = var.log_bucket_suffix
}

# ============================================================================
# Org Policies + VPC Service Controls → movidos a shared-infra/security-global/
# Son recursos PROJECT/ORG-singleton (las org-policies son project-scoped: con
# project_id compartido entre entornos, crearlas por-entorno = 4 states peleando
# por el mismo recurso). Viven en su propio state, se aplican una sola vez.
# ============================================================================

# ============================================================================
# MÓDULO GKE
# ============================================================================
module "gke" {
  source = "./gke"

  project_id        = var.project_id
  account_name      = local.account_name
  create_admin_sa   = var.create_admin_sa
  registry_location = var.registry_location
  registry_name     = var.registry_name
}

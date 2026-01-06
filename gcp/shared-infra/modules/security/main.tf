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

  project_id                      = var.project_id
  admin_groups                    = var.admin_groups
  ci_cd_writer_email              = google_service_account.ci_cd_writer.email
  vm_reader_email                 = google_service_account.vm_reader.email
  break_glass_email               = google_service_account.break_glass.email
  break_glass_max_session_duration = var.break_glass_max_session_duration
  enable_group_iam                = var.enable_group_iam
}

# ============================================================================
# MÓDULO LOGGING
# ============================================================================
module "logging" {
  source = "./logging"

  project_id                 = var.project_id
  env                        = var.env
  is_production              = local.is_production
  break_glass_email          = google_service_account.break_glass.email
  registry_name              = var.registry_name
  alert_notification_channels = var.alert_notification_channels
}

# ============================================================================
# MÓDULO SECURITY
# ============================================================================
module "security" {
  source = "./security"

  project_id                  = var.project_id
  organization_id             = var.organization_id
  allowed_domains              = var.allowed_domains
  enable_vpc_service_controls  = var.enable_vpc_service_controls
  account_name                = local.account_name
  workspace                   = var.workspace
  env                         = var.env
  project_number              = data.google_project.current.number
  is_production               = local.is_production
  enable_org_policies          = var.enable_org_policies
}

# ============================================================================
# MÓDULO GKE
# ============================================================================
module "gke" {
  source = "./gke"

  project_id       = var.project_id
  account_name      = local.account_name
  create_admin_sa  = var.create_admin_sa
  registry_location = var.registry_location
  registry_name     = var.registry_name
}

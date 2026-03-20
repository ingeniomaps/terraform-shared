# ==============================================================================
# SCHEDULING — Encendido/apagado programado de VMs
# ==============================================================================
# Usa Cloud Scheduler para encender y apagar VMs según horario.
# Reduce costos en ambientes dev/qa/stg que no necesitan correr 24/7.
# ==============================================================================

resource "google_cloud_scheduler_job" "start_vm" {
  for_each = var.schedule.enabled ? var.topology : {}

  name        = "${each.key}-${var.environment}-start"
  description = "Encender VM ${each.key}-${var.environment}"
  schedule    = local.start_cron
  time_zone   = var.schedule.timezone
  project     = var.project_id
  region      = var.region

  http_target {
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instances/${each.key}-${var.environment}/start"
    http_method = "POST"

    oauth_token {
      service_account_email = local.service_account_email
    }
  }

  depends_on = [module.vm]
}

resource "google_cloud_scheduler_job" "stop_vm" {
  for_each = var.schedule.enabled ? var.topology : {}

  name        = "${each.key}-${var.environment}-stop"
  description = "Apagar VM ${each.key}-${var.environment}"
  schedule    = local.stop_cron
  time_zone   = var.schedule.timezone
  project     = var.project_id
  region      = var.region

  http_target {
    uri         = "https://compute.googleapis.com/compute/v1/projects/${var.project_id}/zones/${var.zone}/instances/${each.key}-${var.environment}/stop"
    http_method = "POST"

    oauth_token {
      service_account_email = local.service_account_email
    }
  }

  depends_on = [module.vm]
}

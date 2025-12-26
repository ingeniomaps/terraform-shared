# Emails de las cuentas de servicio creadas
output "ci_cd_writer_email" {
  description = "Email de la cuenta CI/CD"
  value       = google_service_account.ci_cd_writer.email
}

output "vm_reader_email" {
  description = "Email de la cuenta VM reader"
  value       = google_service_account.vm_reader.email
}

output "dev_reader_email" {
  description = "Email de la cuenta de developers (null si deshabilitado)"
  value       = var.enable_dev_reader ? google_service_account.dev_reader[0].email : null
}

output "break_glass_email" {
  description = "Email de la cuenta Break Glass"
  value       = google_service_account.break_glass.email
  sensitive   = true
}

# Información del ambiente
output "environment" {
  description = "Ambiente actual"
  value       = var.env
}

output "is_production" {
  description = "Indica si es ambiente de producción"
  value       = local.is_production
}

# ==============================================================================
# Outputs — Cloud Armor Security Policy
# ==============================================================================

output "policy_name" {
  description = "Nombre de la security policy"
  value       = google_compute_security_policy.waf.name
}

output "policy_id" {
  description = "ID de la security policy"
  value       = google_compute_security_policy.waf.id
}

output "policy_self_link" {
  description = "Self link de la security policy"
  value       = google_compute_security_policy.waf.self_link
}

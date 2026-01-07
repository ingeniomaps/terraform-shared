# ============================================================================
# FIREWALL: HTTP/HTTPS RESTRINGIDO (mutuamente excluyente con público)
# ============================================================================
resource "google_compute_firewall" "allow_http_https_restricted" {
  count = var.enable_restricted_http ? 1 : 0

  name    = "${var.network_name}-allow-http-https-restricted"
  network = var.vpc_name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = var.corporate_ip_ranges

  target_service_accounts = [
    var.vm_service_account_email
  ]

  description = "Acceso HTTP/HTTPS solo desde IPs corporativas: ${join(", ", var.corporate_ip_ranges)}"
}

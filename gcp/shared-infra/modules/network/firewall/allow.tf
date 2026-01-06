# ============================================================================
# FIREWALL: TRÁFICO INTERNO ENTRE VMs
# ============================================================================
resource "google_compute_firewall" "allow_internal_vms" {
  name    = "${local.network_name}-allow-internal-vms"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "3306", "5432"] # SSH, HTTP, HTTPS, MySQL, PostgreSQL
  }

  allow {
    protocol = "udp"
    ports    = ["53"] # DNS
  }

  allow {
    protocol = "icmp" # Ping
  }

  source_ranges = [var.vm_subnet_cidr]

  target_service_accounts = [
    var.vm_service_account_email
  ]

  description = "Tráfico interno entre VMs en subnet ${var.vm_subnet_cidr}"
}

# ============================================================================
# FIREWALL: HTTP/HTTPS PÚBLICO (mutuamente excluyente con restringido)
# ============================================================================
resource "google_compute_firewall" "allow_http_https_public" {
  count = var.enable_public_http ? 1 : 0

  name    = "${local.network_name}-allow-http-https-public"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]

  target_service_accounts = [
    var.vm_service_account_email
  ]

  description = "Acceso HTTP/HTTPS público vía Load Balancer"
}

# ============================================================================
# FIREWALL: HEALTH CHECKS DE LOAD BALANCER
# ============================================================================
resource "google_compute_firewall" "allow_health_checks" {
  name    = "${local.network_name}-allow-health-checks"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  target_service_accounts = [
    var.vm_service_account_email
  ]

  description = "Health checks de Google Cloud Load Balancer"
}

# ============================================================================
# FIREWALL: SSH VÍA IAP
# ============================================================================
resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "${local.network_name}-allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]

  # Usar tags en lugar de service accounts para mayor flexibilidad
  # Las VMs deben tener el tag "allow-iap-ssh" para permitir SSH vía IAP
  target_tags = ["allow-iap-ssh"]

  description = "SSH solo mediante Identity-Aware Proxy (rango IAP: 35.235.240.0/20)"
}
# ============================================================================
# FIREWALL GKE: MASTER → NODES
# ============================================================================
resource "google_compute_firewall" "gke_master_to_nodes" {
  count   = var.enable_gke ? 1 : 0

  name    = "${local.network_name}-gke-master-to-nodes"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443", "10250", "8443"] # API server, kubelet, webhook
  }

  source_ranges = [var.gke_master_cidr]
  target_tags   = ["gke-${local.network_name}"]

  description = "Comunicación GKE control plane → nodes"
}

# ============================================================================
# FIREWALL GKE: NODES → MASTER
# ============================================================================
resource "google_compute_firewall" "gke_nodes_to_master" {
  count   = var.enable_gke ? 1 : 0

  name    = "${local.network_name}-gke-nodes-to-master"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_tags        = ["gke-${local.network_name}"]
  destination_ranges = [var.gke_master_cidr]

  description = "Comunicación GKE nodes → control plane"
}

# ============================================================================
# FIREWALL GKE: TRÁFICO INTERNO ENTRE PODS/NODES
# ============================================================================
resource "google_compute_firewall" "gke_internal" {
  count   = var.enable_gke ? 1 : 0

  name    = "${local.network_name}-gke-internal"
  network = google_compute_network.vpc.name

  # Solo permitir puertos necesarios para Kubernetes
  allow {
    protocol = "tcp"
    ports = [
      "443",        # HTTPS
      "8443",       # Webhooks
      "9443",       # Admission controllers
      "10250",      # Kubelet
      "10255",      # Read-only kubelet
      "4443",       # Calico/network plugin
      "5473",       # Calico
    ]
  }

  allow {
    protocol = "udp"
    ports = [
      "53",         # DNS
      "4789",       # VXLAN
    ]
  }

  allow {
    protocol = "icmp"
  }

  # Permitir tráfico desde/hacia estos rangos
  source_ranges = [
    var.gke_subnet_cidr,
    var.gke_pods_cidr,
    var.gke_services_cidr,
  ]

  target_tags = ["gke-${local.network_name}"]

  description = "Tráfico interno GKE - Solo puertos necesarios para Kubernetes"
}

# ============================================================================
# FIREWALL GKE: HEALTH CHECKS
# ============================================================================
resource "google_compute_firewall" "gke_health_checks" {
  count   = var.enable_gke ? 1 : 0

  name    = "${local.network_name}-gke-health-checks"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22",
  ]

  target_tags = ["gke-${local.network_name}"]

  description = "Health checks para GKE LoadBalancer Services"
}

# ============================================================================
# FIREWALL GKE: SSH VÍA IAP PARA TROUBLESHOOTING
# ============================================================================
resource "google_compute_firewall" "gke_allow_iap_ssh" {
  count   = var.enable_gke ? 1 : 0

  name    = "${local.network_name}-gke-allow-iap-ssh"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = ["gke-${local.network_name}"]

  description = "SSH a nodes GKE solo vía IAP para troubleshooting"
}
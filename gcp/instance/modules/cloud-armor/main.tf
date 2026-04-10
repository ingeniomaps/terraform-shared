# ==============================================================================
# Cloud Armor — Security Policy genérica para GKE
# ==============================================================================
# Crea una policy con:
#   - Reglas OWASP CRS (SQLi, XSS, LFI, RFI, RCE, protocol, scanner)
#   - Rate limiting configurable por path
#   - Bloqueo/allowlist de IPs
#   - Geo-blocking
#   - Protección adaptativa (ML)
#
# Los paths de rate limiting se pasan como variable, permitiendo reusar
# el módulo en cualquier servicio (Keycloak, APIs, frontends).
# ==============================================================================

locals {
  owasp_rules = var.enable_owasp_rules ? {
    sqli = {
      priority   = 1000
      expression = "evaluatePreconfiguredWaf('sqli-v33-stable', {'sensitivity': ${var.owasp_sensitivity}})"
      desc       = "Block SQL injection"
    }
    xss = {
      priority   = 1001
      expression = "evaluatePreconfiguredWaf('xss-v33-stable', {'sensitivity': ${var.owasp_sensitivity}})"
      desc       = "Block cross-site scripting"
    }
    lfi = {
      priority   = 1002
      expression = "evaluatePreconfiguredWaf('lfi-v33-stable', {'sensitivity': 1})"
      desc       = "Block local file inclusion"
    }
    rfi = {
      priority   = 1003
      expression = "evaluatePreconfiguredWaf('rfi-v33-stable', {'sensitivity': 1})"
      desc       = "Block remote file inclusion"
    }
    rce = {
      priority   = 1004
      expression = "evaluatePreconfiguredWaf('rce-v33-stable', {'sensitivity': 1})"
      desc       = "Block remote code execution"
    }
    protocol = {
      priority   = 1005
      expression = "evaluatePreconfiguredWaf('protocolattack-v33-stable', {'sensitivity': 1})"
      desc       = "Block HTTP protocol attacks"
    }
    scanner = {
      priority   = 1006
      expression = "evaluatePreconfiguredWaf('scannerdetection-v33-stable', {'sensitivity': 1})"
      desc       = "Block automated scanners"
    }
  } : {}
}

resource "google_compute_security_policy" "waf" {
  name        = var.policy_name
  project     = var.project_id
  description = var.description

  # ── Default: allow ─────────────────────────────────────────────
  rule {
    action   = "allow"
    priority = 2147483647
    match {
      versioned_expr = "SRC_IPS_V1"
      config {
        src_ip_ranges = ["*"]
      }
    }
    description = "Default: allow all traffic"
  }

  # ── IP allowlist (si se configura, solo estos IPs pasan) ───────
  dynamic "rule" {
    for_each = length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      action   = "deny(403)"
      priority = 100
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = ["*"]
        }
      }
      description = "Deny all (allowlist mode)"
    }
  }

  dynamic "rule" {
    for_each = length(var.allowed_ip_ranges) > 0 ? [1] : []
    content {
      action   = "allow"
      priority = 99
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.allowed_ip_ranges
        }
      }
      description = "Allow only whitelisted IPs"
    }
  }

  # ── IP blocklist ───────────────────────────────────────────────
  dynamic "rule" {
    for_each = length(var.blocked_ip_ranges) > 0 ? [1] : []
    content {
      action   = "deny(403)"
      priority = 500
      match {
        versioned_expr = "SRC_IPS_V1"
        config {
          src_ip_ranges = var.blocked_ip_ranges
        }
      }
      description = "Block specific IP ranges"
    }
  }

  # ── Geo-blocking ───────────────────────────────────────────────
  dynamic "rule" {
    for_each = length(var.blocked_countries) > 0 ? [1] : []
    content {
      action   = "deny(403)"
      priority = 600
      match {
        expr {
          expression = "origin.region_code in [${join(",", formatlist("'%s'", var.blocked_countries))}]"
        }
      }
      description = "Block traffic from specific countries"
    }
  }

  # ── OWASP CRS rules ───────────────────────────────────────────
  dynamic "rule" {
    for_each = local.owasp_rules
    content {
      action   = "deny(403)"
      priority = rule.value.priority
      match {
        expr {
          expression = rule.value.expression
        }
      }
      description = rule.value.desc
    }
  }

  # ── Rate limiting (custom per path) ────────────────────────────
  dynamic "rule" {
    for_each = var.rate_limit_rules
    content {
      action   = "throttle"
      priority = rule.value.priority
      match {
        expr {
          expression = "request.path.matches('${rule.value.path_pattern}')"
        }
      }
      rate_limit_options {
        conform_action = "allow"
        exceed_action  = "deny(429)"
        rate_limit_threshold {
          count        = rule.value.count
          interval_sec = rule.value.interval_sec
        }
        enforce_on_key = "IP"
      }
      description = "Rate limit: ${rule.value.name}"
    }
  }

  # ── Adaptive protection ────────────────────────────────────────
  adaptive_protection_config {
    layer_7_ddos_defense_config {
      enable = var.enable_adaptive_protection
    }
  }
}

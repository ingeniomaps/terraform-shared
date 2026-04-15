# ==============================================================================
# Variables — Cloud Armor Security Policy
# ==============================================================================

variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "policy_name" {
  description = "Nombre de la security policy (ej: platform-prod-waf)"
  type        = string
}

variable "description" {
  description = "Descripcion de la policy"
  type        = string
  default     = "Cloud Armor WAF policy"
}

# ── OWASP Rules ─────────────────────────────────────────────────
variable "enable_owasp_rules" {
  description = "Habilitar reglas OWASP CRS (SQLi, XSS, LFI, RFI, RCE, protocol attacks, scanner detection)"
  type        = bool
  default     = true
}

variable "owasp_sensitivity" {
  description = "Nivel de sensibilidad OWASP (1=bajo, 2=medio, 3=alto). Mas alto = mas falsos positivos"
  type        = number
  default     = 2

  validation {
    condition     = var.owasp_sensitivity >= 1 && var.owasp_sensitivity <= 4
    error_message = "owasp_sensitivity debe estar entre 1 y 4"
  }
}

# ── Rate Limiting ────────────────────────────────────────────────
variable "rate_limit_rules" {
  description = "Reglas de rate limiting custom. Cada regla define un path pattern y limites por IP"
  type = list(object({
    name         = string
    priority     = number
    path_pattern = string
    count        = number
    interval_sec = number
  }))
  default = []
}

# ── IP Blocking ──────────────────────────────────────────────────
variable "blocked_ip_ranges" {
  description = "Rangos CIDR a bloquear (ej: [\"1.2.3.0/24\"])"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "Rangos CIDR permitidos para acceso restringido. Si no esta vacio, solo estos IPs pueden acceder"
  type        = list(string)
  default     = []
}

# ── Geo-blocking ─────────────────────────────────────────────────
variable "blocked_countries" {
  description = "Codigos ISO 3166-1 alpha-2 de paises a bloquear (ej: [\"CN\", \"RU\"])"
  type        = list(string)
  default     = []
}

# ── Adaptive Protection ──────────────────────────────────────────
variable "enable_adaptive_protection" {
  description = "Habilitar proteccion adaptativa (deteccion de anomalias con ML)"
  type        = bool
  default     = true
}

# ── Labels ───────────────────────────────────────────────────────
variable "labels" {
  description = "Labels adicionales para el recurso"
  type        = map(string)
  default     = {}
}

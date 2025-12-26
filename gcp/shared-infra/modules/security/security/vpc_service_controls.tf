# ============================================================================
# VPC SERVICE CONTROLS: Perímetro de seguridad de red
#
# Este recurso crea un Service Perimeter en GCP para limitar el acceso a los
# servicios y recursos del proyecto, aumentando la seguridad.
# ============================================================================

resource "google_access_context_manager_service_perimeter" "network_perimeter" {
  count  = var.enable_vpc_service_controls ? 1 : 0

  # Política de la organización a la que pertenece este perímetro
  parent = "accessPolicies/${var.organization_id}"

  name   = "accessPolicies/${var.organization_id}/servicePerimeters/${local.account_name}_perimeter"
  title  = "Network Security Perimeter - ${var.workspace} ${var.env}"

  status {
    # Servicios restringidos dentro del perímetro
    restricted_services = [
      "compute.googleapis.com",
      "container.googleapis.com",
      "artifactregistry.googleapis.com",
      "storage.googleapis.com"
    ]

    # Recursos incluidos en el perímetro (el proyecto actual)
    resources = [
      "projects/${data.google_project.current.number}"
    ]

    # Servicios accesibles desde dentro del perímetro
    vpc_accessible_services {
      enable_restriction = true
      allowed_services = [
        "compute.googleapis.com",
        "container.googleapis.com",
        "artifactregistry.googleapis.com",
        "storage.googleapis.com",
        "logging.googleapis.com",
        "monitoring.googleapis.com"
      ]
    }

    # Reglas de ingreso (ingress)
    ingress_policies {
      ingress_from {
        sources {
          resource = "projects/${data.google_project.current.number}" # Permite tráfico desde el proyecto
        }
        identity_type = "ANY_IDENTITY"
      }
      ingress_to {
        resources = ["*"]
        operations {
          service_name = "compute.googleapis.com"
          method_selectors {
            method = "*"  # Permite todos los métodos
          }
        }
      }
    }

    # Reglas de salida (egress)
    egress_policies {
      egress_from {
        identity_type = "ANY_IDENTITY"
      }
      egress_to {
        resources = ["*"]
        operations {
          service_name = "storage.googleapis.com"
          method_selectors {
            method = "*"  # Permite todos los métodos
          }
        }
      }
    }
  }

  # Ignora cambios en la lista de recursos del perímetro para evitar recreaciones innecesarias
  lifecycle {
    ignore_changes = [status[0].resources]
  }
}

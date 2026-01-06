# ============================================================================
# ORGANIZATION POLICIES: Configuración de restricciones y reglas de seguridad
#
# Estos recursos aplican políticas de la organización para reforzar seguridad
# y cumplimiento dentro del proyecto de GCP.
# ============================================================================

# Restringe el peering de VPC, evitando que se puedan enlazar redes entre proyectos
resource "google_org_policy_policy" "restrict_vpc_peering" {
  name   = "projects/${var.project_id}/policies/compute.restrictVpcPeering"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Permite únicamente miembros de dominios específicos en políticas IAM
resource "google_org_policy_policy" "allowed_policy_member_domains" {
  name   = "projects/${var.project_id}/policies/iam.allowedPolicyMemberDomains"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      values {
        allowed_values = var.allowed_domains
      }
    }
  }
}

# Deshabilita la creación de claves de Service Accounts para reforzar seguridad
resource "google_org_policy_policy" "disable_service_account_key_creation" {
  name   = "projects/${var.project_id}/policies/iam.disableServiceAccountKeyCreation"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Restringe la posibilidad de que el proyecto sea host de Shared VPC
resource "google_org_policy_policy" "restrict_shared_vpc_host" {
  name   = "projects/${var.project_id}/policies/compute.restrictSharedVpcHostProjects"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Obliga el uso de OS Login en todas las instancias de Compute Engine
resource "google_org_policy_policy" "require_os_login" {
  name   = "projects/${var.project_id}/policies/compute.requireOsLogin"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Obliga a usar Shielded VM para mayor seguridad
# Solo se aplica en ambientes de producción
resource "google_org_policy_policy" "require_shielded_vm" {
  count  = local.is_production ? 1 : 0
  name   = "projects/${var.project_id}/policies/compute.requireShieldedVm"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

# Evita la creación automática de la red por defecto
resource "google_org_policy_policy" "skip_default_network" {
  name   = "projects/${var.project_id}/policies/compute.skipDefaultNetworkCreation"
  parent = "projects/${var.project_id}"
  spec {
    rules {
      enforce = "TRUE"
    }
  }
}

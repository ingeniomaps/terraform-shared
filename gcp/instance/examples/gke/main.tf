terraform {
  required_version = ">= 1.14.2"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 7.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      # 3.0.x ha mostrado errores tipo "Unexpected Identity Change" durante refresh/destroy
      # (provider devuelve identidad nula y luego identidad real en la misma lectura).
      # Para estabilidad, mantenemos la serie 2.x.
      version = ">= 2.0, < 3.0.0"
    }
  }

  # Por defecto usa backend local (estado en .terraform/).
  # Usa backend GCS (recomendado para producción):
  #
  # backend "gcs" {
  #   bucket = "tu-terraform-state-bucket"
  #   prefix = "instances/gke/dev"
  # }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  credentials = var.credentials_file != null ? file("${path.root}/../keys/${var.credentials_file}") : null
}

# Data sources para obtener información de la infraestructura compartida
data "terraform_remote_state" "shared_infra" {
  backend = "gcs"
  config = {
    bucket = var.shared_infra_state_bucket
    prefix = var.shared_infra_state_prefix
  }
}

# Data source para obtener token de acceso para Kubernetes
data "google_client_config" "current" {}

# Provider de Kubernetes para gestionar recursos de K8s
# Se configura después de que el cluster esté creado
provider "kubernetes" {
  host                   = "https://${module.gke_cluster.cluster_endpoint}"
  token                  = data.google_client_config.current.access_token
  cluster_ca_certificate = base64decode(module.gke_cluster.cluster_ca_certificate)
}

# Validación: Verificar que GKE esté habilitado en shared-infra
locals {
  gke_enabled = try(data.terraform_remote_state.shared_infra.outputs.gke_subnet_name, null) != null

  # Mensaje de error si GKE no está habilitado
  gke_error_message = <<-EOT
    ERROR: GKE no está habilitado en shared-infra.

    Para habilitar GKE:
    1. Edita shared-infra/environments/staging/terraform.tfvars o shared-infra/environments/production/terraform.tfvars
    2. Configura:
       enable_gke        = true
       gke_subnet_cidr   = "10.0.10.0/24"
       gke_pods_cidr     = "10.1.0.0/16"
       gke_services_cidr = "10.2.0.0/16"
       gke_master_cidr   = "172.16.0.0/28"
    3. Aplica los cambios en shared-infra (staging o production):
       cd shared-infra/environments/staging  # o production
       terraform apply
    4. Luego regresa aquí y ejecuta terraform apply nuevamente
  EOT
}

# Precondition check
check "gke_enabled_check" {
  assert {
    condition     = local.gke_enabled
    error_message = local.gke_error_message
  }
}

module "gke_cluster" {
  # Módulo local (por defecto, para desarrollo)
  source = "../../modules/gke"

  # Opción 1: Módulo remoto desde tag/versión (recomendado para producción)
  # source = "git::https://github.com/tu-org/terraform-gcp.git//instance/modules/gke?ref=v1.0.0"

  # Opción 2: Módulo remoto desde branch (solo para desarrollo)
  # source = "git::https://github.com/tu-org/terraform-gcp.git//instance/modules/gke?ref=main"

  project_id                        = var.project_id
  region                            = var.region
  cluster_name                      = var.cluster_name
  gke_subnet_name                   = try(data.terraform_remote_state.shared_infra.outputs.gke_subnet_name, null)
  gke_pods_range_name               = try(data.terraform_remote_state.shared_infra.outputs.gke_pods_range_name, null)
  gke_services_range_name           = try(data.terraform_remote_state.shared_infra.outputs.gke_services_range_name, null)
  gke_master_cidr                   = var.gke_master_cidr
  node_pool_name                    = var.node_pool_name
  node_machine_type                 = var.node_machine_type
  node_disk_size                    = var.node_disk_size
  node_disk_type                    = var.node_disk_type
  min_node_count                    = var.min_node_count
  max_node_count                    = var.max_node_count
  initial_node_count                = var.initial_node_count
  enable_autoscaling                = var.enable_autoscaling
  enable_autorepair                 = var.enable_autorepair
  enable_autoupgrade                = var.enable_autoupgrade
  service_account_email             = try(data.terraform_remote_state.shared_infra.outputs.vm_reader_email, null)
  workload_identity_pool            = var.workload_identity_pool
  kubernetes_version                = var.kubernetes_version
  enable_private_nodes              = var.enable_private_nodes
  enable_private_endpoint           = var.enable_private_endpoint
  master_authorized_networks        = var.master_authorized_networks
  labels                            = var.labels
  network_tags                      = var.network_tags
  enable_http_load_balancing        = var.enable_http_load_balancing
  enable_horizontal_pod_autoscaling = var.enable_horizontal_pod_autoscaling
  enable_network_policy             = var.enable_network_policy
  maintenance_window_start_time     = var.maintenance_window_start_time
  maintenance_window_day            = var.maintenance_window_day
  deletion_protection               = var.deletion_protection
}

# ============================================================================
# KUBERNETES DEPLOYMENT - Aplicación desde Artifact Registry
# ============================================================================

# Namespace para la aplicación
# Nota: El namespace "default" ya existe en Kubernetes, solo lo creamos si es diferente
resource "kubernetes_namespace_v1" "app" {
  count = var.app_namespace != "default" ? 1 : 0

  metadata {
    name = var.app_namespace
    labels = {
      managed_by = "terraform"
      env        = var.env
    }
  }

  depends_on = [module.gke_cluster]
}

# Local para obtener el nombre del namespace (creado o default)
locals {
  app_namespace_name = var.app_namespace
}

# Secret para autenticación con Artifact Registry
resource "kubernetes_secret_v1" "artifact_registry" {
  metadata {
    name      = "artifact-registry-secret"
    namespace = local.app_namespace_name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "${var.region}-docker.pkg.dev" = {
          auth = base64encode("oauth2accesstoken:${data.google_client_config.current.access_token}")
        }
      }
    })
  }

  # Nota: El namespace "default" ya existe en Kubernetes
  # Si usas otro namespace, se creará automáticamente antes que este secret
  depends_on = [module.gke_cluster]
}

# Deployment de la aplicación
resource "kubernetes_deployment_v1" "app" {
  metadata {
    name      = var.app_name
    namespace = local.app_namespace_name
    labels = {
      app     = var.app_name
      version = var.app_image_tag
      managed_by = "terraform"
    }
  }

  spec {
    replicas = var.app_replicas

    # Estrategia de actualización: Rolling Update (sin downtime)
    # Actualiza pod por pod, manteniendo el servicio disponible durante la actualización
    strategy {
      type = "RollingUpdate"
      rolling_update {
        # Actualizar 1 pod a la vez (más conservador)
        # max_unavailable = 0 significa que siempre hay pods disponibles
        max_unavailable = "0"
        # max_surge = "25%" significa que puede crear hasta 25% más pods durante la actualización
        # Esto permite tener pods nuevos listos antes de eliminar los viejos
        max_surge = "25%"
      }
    }

    selector {
      match_labels = {
        app = var.app_name
      }
    }

    template {
      metadata {
        labels = {
          app     = var.app_name
          version = var.app_image_tag
        }
      }

      spec {
        # Configurar autenticación con Artifact Registry
        image_pull_secrets {
          name = kubernetes_secret_v1.artifact_registry.metadata[0].name
        }

        container {
          name  = var.app_name
          image = "${var.artifact_registry_url}/${var.app_image_name}:${var.app_image_tag}"

          port {
            container_port = var.app_container_port
            name          = "http"
          }

          resources {
            requests = {
              cpu    = var.app_cpu_request
              memory = var.app_memory_request
            }
            limits = {
              cpu    = var.app_cpu_limit
              memory = var.app_memory_limit
            }
          }

          liveness_probe {
            http_get {
              path = var.app_liveness_path
              port = var.app_container_port
            }
            initial_delay_seconds = 30
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3
          }

          readiness_probe {
            http_get {
              path = var.app_readiness_path
              port = var.app_container_port
            }
            initial_delay_seconds = 10
            period_seconds        = 5
            timeout_seconds       = 3
            failure_threshold     = 3
          }
        }

        # Usar Service Account para Workload Identity (si está configurado)
        # service_account_name = var.app_service_account_name
      }
    }
  }

  depends_on = [
    kubernetes_secret_v1.artifact_registry,
    module.gke_cluster
  ]
}

# ============================================================================
# KUBERNETES SERVICE - Exponer la aplicación dentro del cluster
# ============================================================================

resource "kubernetes_service_v1" "app" {
  metadata {
    name      = var.app_name
    namespace = local.app_namespace_name
    labels = {
      app = var.app_name
    }
  }

  spec {
    type = "ClusterIP"

    selector = {
      app = var.app_name
    }

    port {
      port        = var.app_service_port
      target_port = var.app_container_port
      protocol    = "TCP"
      name        = "http"
    }
  }

  depends_on = [kubernetes_deployment_v1.app]
}

# ============================================================================
# KUBERNETES INGRESS - Load Balancer para acceso externo
# ============================================================================

resource "kubernetes_ingress_v1" "app" {
  metadata {
    name      = "${var.app_name}-ingress"
    namespace = local.app_namespace_name
    annotations = {
      "kubernetes.io/ingress.class"                = "gce"
      "kubernetes.io/ingress.global-static-ip-name" = var.app_static_ip_name != "" ? var.app_static_ip_name : null
      "kubernetes.io/ingress.allow-http"           = "true"
    }
    labels = {
      app = var.app_name
    }
  }

  spec {
    rule {
      host = var.app_domain != "" ? var.app_domain : null
      http {
        path {
          path      = "/"
          path_type = "Prefix"
          backend {
            service {
              name = kubernetes_service_v1.app.metadata[0].name
              port {
                number = var.app_service_port
              }
            }
          }
        }
      }
    }
  }

  depends_on = [kubernetes_service_v1.app]
}

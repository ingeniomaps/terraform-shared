variable "project_id" {
  description = "ID del proyecto GCP"
  type        = string
}

variable "region" {
  description = "Región donde se creará el cluster"
  type        = string
  default     = "us-central1"
}

variable "credentials_file" {
  description = "Nombre del archivo JSON de credenciales (opcional, debe estar en ../keys/). Si no se especifica, se usa GOOGLE_APPLICATION_CREDENTIALS o gcloud auth."
  type        = string
  default     = null
  sensitive   = true
}

variable "shared_infra_state_bucket" {
  description = "Bucket donde está el estado de la infraestructura compartida"
  type        = string
}

variable "shared_infra_state_prefix" {
  description = "Prefijo del estado de la infraestructura compartida (debe coincidir con el backend de shared-infra)"
  type        = string
}

variable "cluster_name" {
  description = "Nombre del cluster GKE"
  type        = string
  default     = "gke-dev"
}

variable "gke_master_cidr" {
  description = "CIDR para el control plane (debe coincidir con shared-infra)"
  type        = string
  default     = "172.16.0.0/28"
}

variable "node_pool_name" {
  description = "Nombre del node pool"
  type        = string
  default     = "default-pool"
}

variable "node_machine_type" {
  description = "Tipo de máquina para los nodos"
  type        = string
  default     = "e2-medium"
}

variable "node_disk_size" {
  description = "Tamaño del disco de los nodos en GB"
  type        = number
  default     = 50
}

variable "node_disk_type" {
  description = "Tipo de disco de los nodos"
  type        = string
  default     = "pd-standard"
}

variable "min_node_count" {
  description = "Número mínimo de nodos"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Número máximo de nodos"
  type        = number
  default     = 3
}

variable "initial_node_count" {
  description = "Número inicial de nodos"
  type        = number
  default     = 1
}

variable "enable_autoscaling" {
  description = "Habilitar auto-scaling"
  type        = bool
  default     = true
}

variable "enable_autorepair" {
  description = "Habilitar auto-repair"
  type        = bool
  default     = true
}

variable "enable_autoupgrade" {
  description = "Habilitar auto-upgrade"
  type        = bool
  default     = true
}

variable "kubernetes_version" {
  description = "Versión de Kubernetes (vacío para última estable)"
  type        = string
  default     = ""
}

variable "enable_private_nodes" {
  description = "Usar nodos privados"
  type        = bool
  default     = true
}

variable "enable_private_endpoint" {
  description = "Habilitar endpoint privado del control plane"
  type        = bool
  default     = false
}

variable "master_authorized_networks" {
  description = "Redes autorizadas para acceder al control plane"
  type        = map(string)
  default     = {}
}

variable "labels" {
  description = "Labels para el cluster y nodos"
  type        = map(string)
  default     = {}
}

variable "network_tags" {
  description = "Network tags para los nodos"
  type        = list(string)
  default     = []
}

variable "enable_http_load_balancing" {
  description = "Habilitar HTTP Load Balancing"
  type        = bool
  default     = true
}

variable "enable_horizontal_pod_autoscaling" {
  description = "Habilitar Horizontal Pod Autoscaling"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Habilitar Network Policy"
  type        = bool
  default     = false
}

variable "maintenance_window_start_time" {
  description = "Inicio de la ventana de mantenimiento (HH:MM)"
  type        = string
  default     = "02:00"
}

variable "maintenance_window_day" {
  description = "Día de la ventana de mantenimiento"
  type        = string
  default     = "SUNDAY"
}

variable "deletion_protection" {
  description = "Habilitar protección contra eliminación del cluster. IMPORTANTE: Debe ser false para poder destruir el cluster."
  type        = bool
  default     = true
}

variable "workload_identity_pool" {
  description = "Workload Identity Pool (opcional). Si está vacío, se usa el pool por defecto del proyecto."
  type        = string
  default     = ""
}

# ============================================================================
# VARIABLES DE APLICACIÓN KUBERNETES
# ============================================================================

variable "env" {
  description = "Ambiente (dev, stg, prod)"
  type        = string
  default     = "prod"
}

variable "artifact_registry_url" {
  description = "URL completa del Artifact Registry (ej: us-central1-docker.pkg.dev/project-id/repo-name)"
  type        = string
}

variable "app_name" {
  description = "Nombre de la aplicación (usado para deployment, service, ingress)"
  type        = string
  default     = "app"
}

variable "app_namespace" {
  description = "Namespace de Kubernetes para la aplicación"
  type        = string
  default     = "default"
}

variable "app_image_name" {
  description = "Nombre de la imagen Docker en Artifact Registry (sin tag, ej: hello-world)"
  type        = string
}

variable "app_image_tag" {
  description = "Tag de la imagen Docker (ej: latest, 1.0.0, sha256:...)"
  type        = string
  default     = "latest"
}

variable "app_replicas" {
  description = "Número de réplicas del deployment"
  type        = number
  default     = 2
}

variable "app_container_port" {
  description = "Puerto del contenedor donde escucha la aplicación"
  type        = number
  default     = 80
}

variable "app_service_port" {
  description = "Puerto del Service de Kubernetes"
  type        = number
  default     = 80
}

variable "app_liveness_path" {
  description = "Ruta para el liveness probe"
  type        = string
  default     = "/"
}

variable "app_readiness_path" {
  description = "Ruta para el readiness probe"
  type        = string
  default     = "/"
}

variable "app_cpu_request" {
  description = "CPU solicitada para cada pod (ej: 100m, 0.5, 1)"
  type        = string
  default     = "100m"
}

variable "app_memory_request" {
  description = "Memoria solicitada para cada pod (ej: 128Mi, 512Mi, 1Gi)"
  type        = string
  default     = "128Mi"
}

variable "app_cpu_limit" {
  description = "Límite de CPU para cada pod (ej: 500m, 1, 2)"
  type        = string
  default     = "500m"
}

variable "app_memory_limit" {
  description = "Límite de memoria para cada pod (ej: 256Mi, 512Mi, 1Gi)"
  type        = string
  default     = "256Mi"
}

variable "app_domain" {
  description = "Dominio para el Ingress (opcional, vacío para usar IP del Load Balancer)"
  type        = string
  default     = ""
}

variable "app_static_ip_name" {
  description = "Nombre de la IP estática reservada para el Load Balancer (opcional)"
  type        = string
  default     = ""
}

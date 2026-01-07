# ============================================================================
# OUTPUTS: Re-exportar outputs del módulo gke
# ============================================================================

output "cluster_id" {
  description = "ID del cluster GKE"
  value       = module.gke_cluster.cluster_id
}

output "cluster_name" {
  description = "Nombre del cluster GKE"
  value       = module.gke_cluster.cluster_name
}

output "cluster_location" {
  description = "Ubicación del cluster"
  value       = module.gke_cluster.cluster_location
}

output "cluster_endpoint" {
  description = "Endpoint del control plane"
  value       = module.gke_cluster.cluster_endpoint
  sensitive   = true
}

output "kubectl_command" {
  description = "Comando para configurar kubectl"
  value       = module.gke_cluster.kubectl_command
}

output "node_pool_id" {
  description = "ID del node pool"
  value       = module.gke_cluster.node_pool_id
}

output "node_pool_name" {
  description = "Nombre del node pool"
  value       = module.gke_cluster.node_pool_name
}

output "workload_identity_pool" {
  description = "Workload Identity Pool configurado"
  value       = module.gke_cluster.workload_identity_pool
}

output "autoscaling_min_nodes" {
  description = "Número mínimo de nodos (auto-scaling). Null si auto-scaling está deshabilitado."
  value       = module.gke_cluster.autoscaling_min_nodes
}

output "autoscaling_max_nodes" {
  description = "Número máximo de nodos (auto-scaling). Null si auto-scaling está deshabilitado."
  value       = module.gke_cluster.autoscaling_max_nodes
}

output "current_node_count" {
  description = "Número actual de nodos en el node pool"
  value       = module.gke_cluster.current_node_count
}

# ============================================================================
# OUTPUTS DE LA APLICACIÓN KUBERNETES
# ============================================================================

output "app_namespace" {
  description = "Namespace donde se desplegó la aplicación"
  value       = local.app_namespace_name
}

output "app_deployment_name" {
  description = "Nombre del deployment de la aplicación"
  value       = kubernetes_deployment_v1.app.metadata[0].name
}

output "app_service_name" {
  description = "Nombre del service de la aplicación"
  value       = kubernetes_service_v1.app.metadata[0].name
}

output "app_ingress_name" {
  description = "Nombre del ingress de la aplicación"
  value       = kubernetes_ingress_v1.app.metadata[0].name
}

output "app_load_balancer_ip" {
  description = "IP del Load Balancer del Ingress (puede tardar unos minutos en asignarse)"
  value       = try(kubernetes_ingress_v1.app.status[0].load_balancer[0].ingress[0].ip, "Pending...")
}

output "app_access_url" {
  description = "URL para acceder a la aplicación (usa IP o dominio según configuración)"
  value       = var.app_domain != "" ? "http://${var.app_domain}" : "http://${try(kubernetes_ingress_v1.app.status[0].load_balancer[0].ingress[0].ip, "Pending...")}"
}

output "app_image_full_path" {
  description = "Ruta completa de la imagen Docker desplegada"
  value       = "${var.artifact_registry_url}/${var.app_image_name}:${var.app_image_tag}"
}

output "kubectl_get_services" {
  description = "Comando para ver los services de la aplicación"
  value       = "kubectl get services -n ${local.app_namespace_name}"
}

output "kubectl_get_ingress" {
  description = "Comando para ver el Ingress y obtener la IP del Load Balancer"
  value       = "kubectl get ingress ${kubernetes_ingress_v1.app.metadata[0].name} -n ${local.app_namespace_name}"
}

output "kubectl_get_pods" {
  description = "Comando para ver los pods de la aplicación"
  value       = "kubectl get pods -n ${local.app_namespace_name} -l app=${var.app_name}"
}
